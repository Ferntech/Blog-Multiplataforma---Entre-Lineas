import base64
from fastapi.responses import HTMLResponse
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from decimal import Decimal
import json
import os
from typing import Literal
import urllib.error
import urllib.parse
import urllib.request
import uuid

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pwdlib import PasswordHash
from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from database import obtener_sesion
from models import (
    Author,
    BlogPost,
    BlogVote,
    Book,
    CartItem,
    Comment,
    CommentMedia,
    Invoice,
    Order,
    OrderItem,
    Payment,
    PrivateMessage,
    ShoppingCart,
    Tag,
    User,
)
from schemas import (
    BlogPostResponse,
    BookResponse,
    BookSummary,
    CartItemAdd,
    CartItemResponse,
    CartItemUpdate,
    CommentCreate,
    CommentResponse,
    ConversationSummary,
    GiphyItemResponse,
    LoginRequest,
    OrderResponse,
    PayPalCheckoutRequest,
    PayPalCaptureRequest,
    PayPalOrderCreateResponse,
    PrivateMessageCreate,
    PrivateMessageResponse,
    ShoppingCartResponse,
    TagResponse,
    UserCreate,
    UserResponse,
    UserSummary,
    UserUpdate,
    VoteRequest,
    VoteResponse,
)

password_hash = PasswordHash.recommended()

def verificar_password_compatible(plain_password: str, stored_hash: str) -> bool:
    """Compatibilidad con hashes bcrypt generados por PHP ($2y$) y Python ($2b$)."""
    normalized_hash = stored_hash.replace("$2y$", "$2b$", 1)
    try:
        return password_hash.verify(plain_password, normalized_hash)
    except Exception:
        return False

def obtener_karma_usuario(db: Session, user_id: int) -> int:
    total = db.scalar(
        select(func.coalesce(func.sum(BlogVote.vote_value), 0))
        .join(BlogPost, BlogPost.id == BlogVote.post_id)
        .where(BlogPost.author_id == user_id)
    )
    return int(total or 0)

def serializar_usuario(usuario: User, db: Session) -> UserResponse:
    return UserResponse(
        id=usuario.id,
        full_name=usuario.full_name,
        email=usuario.email,
        role=usuario.role,
        avatar_url=usuario.avatar_url,
        bio=usuario.bio,
        phone=usuario.phone,
        address_line=usuario.address_line,
        city=usuario.city,
        state=usuario.state,
        postal_code=usuario.postal_code,
        country=usuario.country,
        is_active=bool(usuario.is_active),
        karma=obtener_karma_usuario(db, usuario.id),
        created_at=usuario.created_at,
        updated_at=usuario.updated_at,
    )

def serializar_post(
    post: BlogPost,
    db: Session,
    current_user_id: int | None = None,
) -> BlogPostResponse:
    votos_activos = [v.vote_value for v in post.votes]
    user_vote = 0
    if current_user_id is not None:
        voto_usuario = next(
            (v for v in post.votes if v.user_id == current_user_id),
            None,
        )
        if voto_usuario is not None:
            user_vote = voto_usuario.vote_value

    comentarios_visibles = [c for c in post.comments if c.status == "visible"]

    author_summary = None
    if post.author is not None:
        author_summary = UserSummary(
            id=post.author.id,
            full_name=post.author.full_name,
            role=post.author.role,
            avatar_url=post.author.avatar_url,
            karma=obtener_karma_usuario(db, post.author.id),
        )

    book_summary = BookSummary(
        id=post.book.id,
        title=post.book.title,
        slug=post.book.slug,
        isbn_13=post.book.isbn_13,
        cover_url=post.book.cover_url,
        price=float(post.book.price),
        stock=post.book.stock,
        status=post.book.status,
        authors=post.book.authors,
    )

    return BlogPostResponse(
        id=post.id,
        author_id=post.author_id,
        book_id=post.book_id,
        title=post.title,
        slug=post.slug,
        excerpt=post.excerpt,
        content=post.content,
        rating=post.rating,
        status=post.status,
        published_at=post.published_at,
        created_at=post.created_at,
        updated_at=post.updated_at,
        author=author_summary,
        book=book_summary,
        tags=post.tags,
        vote_score=sum(votos_activos),
        user_vote=user_vote,
        comments_count=len(comentarios_visibles),
    )

def construir_respuesta_carrito(cart: ShoppingCart) -> ShoppingCartResponse:
    items_resp: list[CartItemResponse] = []
    subtotal = Decimal("0.00")

    for item in cart.items:
        line_total = (Decimal(str(item.book.price)) * item.quantity).quantize(Decimal("0.01"))
        subtotal += line_total
        items_resp.append(
            CartItemResponse(
                id=item.id,
                book_id=item.book_id,
                quantity=item.quantity,
                line_total=float(line_total),
                book=BookSummary(
                    id=item.book.id,
                    title=item.book.title,
                    slug=item.book.slug,
                    isbn_13=item.book.isbn_13,
                    cover_url=item.book.cover_url,
                    price=float(item.book.price),
                    stock=item.book.stock,
                    status=item.book.status,
                    authors=item.book.authors,
                ),
            )
        )

    shipping = (
        Decimal("0.00")
        if (subtotal == 0 or subtotal >= Decimal("500.00"))
        else Decimal("79.00")
    )
    total = subtotal + shipping

    return ShoppingCartResponse(
        id=cart.id,
        user_id=cart.user_id,
        status=cart.status,
        items=items_resp,
        subtotal=float(subtotal),
        estimated_shipping=float(shipping),
        estimated_total=float(total),
        currency="MXN",
    )

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(
    title="Entre Líneas Mobile API",
    description="API REST para la versión móvil de Entre Líneas sobre entre_lineas_db.",
    version="2.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Estado"])
def inicio():
    return {
        "mensaje": "API Entre Líneas (Móvil) operativa",
        "database": "entre_lineas_db",
    }

@app.post("/auth/login", response_model=UserResponse, tags=["Autenticación"])
@app.post("/login", response_model=UserResponse, tags=["Autenticación"])
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.email.strip().lower()
    usuario = db.scalar(select(User).where(User.email == correo))

    if usuario is None or not verificar_password_compatible(
        datos.password,
        usuario.password_hash,
    ):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

    if usuario.is_active != 1:
        raise HTTPException(status_code=403, detail="Esta cuenta se encuentra desactivada")

    return serializar_usuario(usuario, db)

@app.post("/auth/register", response_model=UserResponse, status_code=201, tags=["Autenticación"])
@app.post("/users", response_model=UserResponse, status_code=201, tags=["Autenticación"])
def registrar_usuario(datos: UserCreate, db: Session = Depends(obtener_sesion)):
    usuario = User(
        full_name=datos.full_name.strip(),
        email=datos.email.strip().lower(),
        password_hash=password_hash.hash(datos.password),
        role="reader",
        avatar_url=datos.avatar_url,
        bio=datos.bio,
        phone=datos.phone,
        address_line=datos.address_line,
        city=datos.city,
        state=datos.state,
        postal_code=datos.postal_code,
        country=datos.country,
        is_active=1,
    )
    db.add(usuario)
    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo electrónico ya está registrado")
    return serializar_usuario(usuario, db)

@app.get("/users/contacts", response_model=list[UserSummary], tags=["Usuarios"])
def listar_contactos_comunidad(
    exclude_user_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    db: Session = Depends(obtener_sesion),
):
    """Lista miembros activos de la comunidad para iniciar conversaciones privadas."""
    stmt = select(User).where(User.is_active == 1).order_by(User.full_name.asc())
    if exclude_user_id is not None:
        stmt = stmt.where(User.id != exclude_user_id)
    if search and search.strip():
        patron = f"%{search.strip()}%"
        stmt = stmt.where(User.full_name.ilike(patron))

    usuarios = db.scalars(stmt).all()
    return [
        UserSummary(
            id=u.id,
            full_name=u.full_name,
            role=u.role,
            avatar_url=u.avatar_url,
            karma=obtener_karma_usuario(db, u.id),
        )
        for u in usuarios
    ]

@app.get("/users/{user_id}", response_model=UserResponse, tags=["Usuarios"])
def obtener_usuario(user_id: int, db: Session = Depends(obtener_sesion)):
    usuario = db.get(User, user_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return serializar_usuario(usuario, db)

@app.put("/users/{user_id}", response_model=UserResponse, tags=["Usuarios"])
def actualizar_usuario(
    user_id: int,
    datos: UserUpdate,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(User, user_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    usuario.full_name = datos.full_name.strip()
    usuario.email = datos.email.strip().lower()
    usuario.avatar_url = datos.avatar_url
    usuario.bio = datos.bio
    usuario.phone = datos.phone
    usuario.address_line = datos.address_line
    usuario.city = datos.city
    usuario.state = datos.state
    usuario.postal_code = datos.postal_code
    usuario.country = datos.country

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo electrónico ya está registrado")
    return serializar_usuario(usuario, db)

@app.get("/tags", response_model=list[TagResponse], tags=["Catálogo"])
def listar_etiquetas(db: Session = Depends(obtener_sesion)):
    return db.scalars(select(Tag).order_by(Tag.name)).all()

@app.get("/books", response_model=list[BookResponse], tags=["Catálogo"])
def listar_libros(
    search: str | None = Query(default=None),
    tag: str | None = Query(default=None),
    db: Session = Depends(obtener_sesion),
):
    stmt = (
        select(Book)
        .options(selectinload(Book.authors), selectinload(Book.tags))
        .where(Book.status.in_(["active", "out_of_stock"]))
        .order_by(Book.title.asc())
    )
    if search and search.strip():
        patron = f"%{search.strip()}%"
        stmt = stmt.outerjoin(Book.authors).where(
            or_(
                Book.title.ilike(patron),
                Book.subtitle.ilike(patron),
                Book.isbn_13.ilike(patron),
                Book.publisher.ilike(patron),
                Author.name.ilike(patron),
            )
        )
    if tag and tag.strip():
        stmt = stmt.join(Book.tags).where(Tag.slug == tag.strip().lower())

    return db.scalars(stmt).unique().all()

@app.get("/books/{book_id}", response_model=BookResponse, tags=["Catálogo"])
def obtener_libro(book_id: int, db: Session = Depends(obtener_sesion)):
    stmt = (
        select(Book)
        .options(selectinload(Book.authors), selectinload(Book.tags))
        .where(Book.id == book_id)
    )
    libro = db.scalar(stmt)
    if libro is None or libro.status not in ("active", "out_of_stock"):
        raise HTTPException(status_code=404, detail="Libro no encontrado en el catálogo")
    return libro

@app.get("/blog-posts", response_model=list[BlogPostResponse], tags=["Reseñas"])
def listar_publicaciones(
    user_id: int | None = Query(default=None),
    book_id: int | None = Query(default=None),
    tag: str | None = Query(default=None),
    search: str | None = Query(default=None),
    db: Session = Depends(obtener_sesion),
):
    stmt = (
        select(BlogPost)
        .options(
            selectinload(BlogPost.author),
            selectinload(BlogPost.book).selectinload(Book.authors),
            selectinload(BlogPost.tags),
            selectinload(BlogPost.votes),
            selectinload(BlogPost.comments),
        )
        .where(BlogPost.status == "published")
        .order_by(
            func.coalesce(BlogPost.published_at, BlogPost.created_at).desc(),
        )
    )
    if book_id is not None:
        stmt = stmt.where(BlogPost.book_id == book_id)
    if tag and tag.strip():
        stmt = stmt.join(BlogPost.tags).where(Tag.slug == tag.strip().lower())
    if search and search.strip():
        patron = f"%{search.strip()}%"
        stmt = stmt.join(BlogPost.book).where(
            or_(
                BlogPost.title.ilike(patron),
                BlogPost.excerpt.ilike(patron),
                Book.title.ilike(patron),
                Book.isbn_13.ilike(patron),
            )
        )

    posts = db.scalars(stmt).unique().all()
    return [serializar_post(p, db, user_id) for p in posts]

@app.get("/blog-posts/{post_id}", response_model=BlogPostResponse, tags=["Reseñas"])
def obtener_publicacion(
    post_id: int,
    user_id: int | None = Query(default=None),
    db: Session = Depends(obtener_sesion),
):
    stmt = (
        select(BlogPost)
        .options(
            selectinload(BlogPost.author),
            selectinload(BlogPost.book).selectinload(Book.authors),
            selectinload(BlogPost.tags),
            selectinload(BlogPost.votes),
            selectinload(BlogPost.comments),
        )
        .where(and_(BlogPost.id == post_id, BlogPost.status == "published"))
    )
    post = db.scalar(stmt)
    if post is None:
        raise HTTPException(status_code=404, detail="Reseña no encontrada")
    return serializar_post(post, db, user_id)

@app.post("/blog-posts/{post_id}/vote", response_model=VoteResponse, tags=["Reseñas"])
def votar_publicacion(
    post_id: int,
    datos: VoteRequest,
    db: Session = Depends(obtener_sesion),
):
    post = db.get(BlogPost, post_id)
    if post is None or post.status != "published":
        raise HTTPException(status_code=404, detail="Reseña no encontrada")

    usuario = db.get(User, datos.user_id)
    if usuario is None or usuario.is_active != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado o inactivo")

    if post.author_id is not None and post.author_id == datos.user_id:
        raise HTTPException(
            status_code=403,
            detail="No puedes votar tu propia publicación",
        )

    voto_existente = db.scalar(
        select(BlogVote).where(
            and_(BlogVote.post_id == post_id, BlogVote.user_id == datos.user_id)
        )
    )

    if datos.vote_value == 0:
        if voto_existente:
            db.delete(voto_existente)
    elif voto_existente:
        voto_existente.vote_value = datos.vote_value
    else:
        db.add(
            BlogVote(
                user_id=datos.user_id,
                post_id=post_id,
                vote_value=datos.vote_value,
            )
        )

    db.commit()
    votos = db.scalars(
        select(BlogVote.vote_value).where(BlogVote.post_id == post_id)
    ).all()
    author_karma = (
        obtener_karma_usuario(db, post.author_id)
        if post.author_id is not None
        else 0
    )

    return VoteResponse(
        post_id=post_id,
        vote_score=sum(votos),
        user_vote=datos.vote_value,
        author_karma=author_karma,
    )

@app.get(
    "/blog-posts/{post_id}/comments",
    response_model=list[CommentResponse],
    tags=["Comentarios y Giphy"],
)
def listar_comentarios_post(post_id: int, db: Session = Depends(obtener_sesion)):
    stmt = (
        select(Comment)
        .options(selectinload(Comment.user), selectinload(Comment.media))
        .where(and_(Comment.post_id == post_id, Comment.status == "visible"))
        .order_by(Comment.created_at.desc(), Comment.id.desc())
    )
    return db.scalars(stmt).all()

@app.post(
    "/blog-posts/{post_id}/comments",
    response_model=CommentResponse,
    status_code=201,
    tags=["Comentarios y Giphy"],
)
def crear_comentario(
    post_id: int,
    datos: CommentCreate,
    db: Session = Depends(obtener_sesion),
):
    post = db.get(BlogPost, post_id)
    if post is None or post.status != "published":
        raise HTTPException(status_code=404, detail="Reseña no encontrada")

    usuario = db.get(User, datos.user_id)
    if usuario is None or usuario.is_active != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado o inactivo")

    texto_limpio = datos.content.strip()
    if texto_limpio == "" and datos.media is None:
        raise HTTPException(
            status_code=422,
            detail="Escribe un comentario o selecciona un GIF/Sticker",
        )

    comentario = Comment(
        post_id=post_id,
        user_id=datos.user_id,
        content=texto_limpio,
        status="visible",
    )
    db.add(comentario)
    db.flush()

    if datos.media is not None:
        db.add(
            CommentMedia(
                comment_id=comentario.id,
                provider="giphy",
                media_type=datos.media.media_type,
                giphy_id=datos.media.giphy_id.strip(),
                media_url=datos.media.media_url.strip(),
                preview_url=datos.media.preview_url,
                width=datos.media.width,
                height=datos.media.height,
                alt_text=datos.media.alt_text,
            )
        )

    db.commit()
    return db.scalar(
        select(Comment)
        .options(selectinload(Comment.user), selectinload(Comment.media))
        .where(Comment.id == comentario.id)
    )

@app.get("/giphy/search", response_model=list[GiphyItemResponse], tags=["Comentarios y Giphy"])
def buscar_giphy(
    q: str = Query(default="", max_length=80),
    media_type: Literal["gif", "sticker"] = Query(default="gif", alias="type"),
    limit: int = Query(default=16, ge=1, le=24),
):
    api_key = os.getenv("GIPHY_API_KEY", "").strip()
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="GIPHY_API_KEY no está configurada en el archivo .env de FastAPI",
        )

    endpoint_tipo = "stickers" if media_type == "sticker" else "gifs"
    query_limpia = q.strip()
    params = {
        "api_key": api_key,
        "limit": str(limit),
        "rating": "pg-13",
        "lang": "es",
    }

    if query_limpia:
        params["q"] = query_limpia
        url = f"https://api.giphy.com/v1/{endpoint_tipo}/search?{urllib.parse.urlencode(params)}"
    else:
        url = f"https://api.giphy.com/v1/{endpoint_tipo}/trending?{urllib.parse.urlencode(params)}"

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "EntreLineasMobile/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except (urllib.error.URLError, TimeoutError):
        raise HTTPException(status_code=502, detail="No se pudo conectar con Giphy")

    items: list[GiphyItemResponse] = []
    for raw in payload.get("data", []):
        images = raw.get("images", {})
        fixed = images.get("fixed_height") or images.get("original") or {}
        preview = images.get("fixed_height_small") or fixed
        media_url = fixed.get("url")
        if not media_url:
            continue

        width_raw = fixed.get("width")
        height_raw = fixed.get("height")
        items.append(
            GiphyItemResponse(
                giphy_id=str(raw.get("id", "")),
                media_type=media_type,
                media_url=media_url,
                preview_url=preview.get("url") or media_url,
                width=int(width_raw) if str(width_raw).isdigit() else None,
                height=int(height_raw) if str(height_raw).isdigit() else None,
                alt_text=(raw.get("title") or "GIF de Giphy")[:200],
            )
        )

    return items

@app.get(
    "/users/{user_id}/conversations",
    response_model=list[ConversationSummary],
    tags=["Mensajes Privados"],
)
def listar_conversaciones(user_id: int, db: Session = Depends(obtener_sesion)):
    stmt = (
        select(PrivateMessage)
        .where(
            or_(
                and_(
                    PrivateMessage.sender_id == user_id,
                    PrivateMessage.sender_deleted_at.is_(None),
                ),
                and_(
                    PrivateMessage.recipient_id == user_id,
                    PrivateMessage.recipient_deleted_at.is_(None),
                ),
            )
        )
        .order_by(PrivateMessage.sent_at.desc(), PrivateMessage.id.desc())
    )
    mensajes = db.scalars(stmt).all()

    agrupadas: dict[int, dict] = {}
    for msg in mensajes:
        partner_id = msg.recipient_id if msg.sender_id == user_id else msg.sender_id
        if partner_id not in agrupadas:
            agrupadas[partner_id] = {
                "last_message": msg.content,
                "last_sent_at": msg.sent_at,
                "last_sender_id": msg.sender_id,
                "unread_count": 0,
            }
        if msg.recipient_id == user_id and msg.read_at is None:
            agrupadas[partner_id]["unread_count"] += 1

    if not agrupadas:
        return []

    partners = {
        u.id: u
        for u in db.scalars(select(User).where(User.id.in_(list(agrupadas.keys())))).all()
    }

    resultado: list[ConversationSummary] = []
    for pid, info in agrupadas.items():
        partner = partners.get(pid)
        if partner is None:
            continue
        resultado.append(
            ConversationSummary(
                partner_id=partner.id,
                partner_name=partner.full_name,
                partner_role=partner.role,
                partner_avatar_url=partner.avatar_url,
                last_message=info["last_message"],
                last_sent_at=info["last_sent_at"],
                last_sender_id=info["last_sender_id"],
                unread_count=info["unread_count"],
            )
        )

    return resultado

@app.get(
    "/users/{user_id}/messages",
    response_model=list[PrivateMessageResponse],
    tags=["Mensajes Privados"],
)
def listar_mensajes_usuario(
    user_id: int,
    with_user_id: int = Query(...),
    db: Session = Depends(obtener_sesion),
):
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)
    db.execute(
        update(PrivateMessage)
        .where(
            and_(
                PrivateMessage.sender_id == with_user_id,
                PrivateMessage.recipient_id == user_id,
                PrivateMessage.read_at.is_(None),
            )
        )
        .values(read_at=ahora)
    )
    db.commit()

    stmt = (
        select(PrivateMessage)
        .where(
            or_(
                and_(
                    PrivateMessage.sender_id == user_id,
                    PrivateMessage.recipient_id == with_user_id,
                    PrivateMessage.sender_deleted_at.is_(None),
                ),
                and_(
                    PrivateMessage.sender_id == with_user_id,
                    PrivateMessage.recipient_id == user_id,
                    PrivateMessage.recipient_deleted_at.is_(None),
                ),
            )
        )
        .order_by(PrivateMessage.sent_at.asc(), PrivateMessage.id.asc())
    )
    return db.scalars(stmt).all()

@app.post(
    "/messages",
    response_model=PrivateMessageResponse,
    status_code=201,
    tags=["Mensajes Privados"],
)
def enviar_mensaje_privado(
    datos: PrivateMessageCreate,
    db: Session = Depends(obtener_sesion),
):
    if datos.sender_id == datos.recipient_id:
        raise HTTPException(
            status_code=422,
            detail="No puedes enviarte un mensaje privado a ti mismo",
        )
    remitente = db.get(User, datos.sender_id)
    destinatario = db.get(User, datos.recipient_id)
    if remitente is None or destinatario is None:
        raise HTTPException(status_code=404, detail="Remitente o destinatario no encontrado")

    mensaje = PrivateMessage(
        sender_id=datos.sender_id,
        recipient_id=datos.recipient_id,
        content=datos.content.strip(),
    )
    db.add(mensaje)
    db.commit()
    db.refresh(mensaje)
    return mensaje

def _obtener_o_crear_carrito_activo(user_id: int, db: Session) -> ShoppingCart:
    if db.get(User, user_id) is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    stmt = (
        select(ShoppingCart)
        .options(
            selectinload(ShoppingCart.items)
            .selectinload(CartItem.book)
            .selectinload(Book.authors)
        )
        .where(and_(ShoppingCart.user_id == user_id, ShoppingCart.status == "active"))
    )
    carrito = db.scalar(stmt)
    if carrito is None:
        carrito = ShoppingCart(user_id=user_id, status="active")
        db.add(carrito)
        db.commit()
        carrito = db.scalar(stmt)
    return carrito

@app.get(
    "/users/{user_id}/cart",
    response_model=ShoppingCartResponse,
    tags=["Tienda y Pedidos"],
)
def ver_carrito(user_id: int, db: Session = Depends(obtener_sesion)):
    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    return construir_respuesta_carrito(carrito)

@app.post(
    "/users/{user_id}/cart/items",
    response_model=ShoppingCartResponse,
    tags=["Tienda y Pedidos"],
)
def agregar_libro_al_carrito(
    user_id: int,
    datos: CartItemAdd,
    db: Session = Depends(obtener_sesion),
):
    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    libro = db.get(Book, datos.book_id)
    if libro is None or libro.status != "active":
        raise HTTPException(
            status_code=400,
            detail="El libro seleccionado no está disponible para compra",
        )

    item_existente = next((i for i in carrito.items if i.book_id == datos.book_id), None)
    nueva_cantidad = (item_existente.quantity if item_existente else 0) + datos.quantity

    if libro.stock < nueva_cantidad:
        raise HTTPException(
            status_code=400,
            detail=f"Stock insuficiente. Disponibles: {libro.stock}",
        )

    if item_existente:
        item_existente.quantity = nueva_cantidad
    else:
        db.add(CartItem(cart_id=carrito.id, book_id=libro.id, quantity=datos.quantity))

    db.commit()
    return ver_carrito(user_id, db)

@app.put(
    "/users/{user_id}/cart/items/{item_id}",
    response_model=ShoppingCartResponse,
    tags=["Tienda y Pedidos"],
)
def actualizar_cantidad_carrito(
    user_id: int,
    item_id: int,
    datos: CartItemUpdate,
    db: Session = Depends(obtener_sesion),
):
    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    item = next((i for i in carrito.items if i.id == item_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail="Artículo no encontrado en el carrito")

    if item.book.stock < datos.quantity:
        raise HTTPException(
            status_code=400,
            detail=f"Stock insuficiente. Disponibles: {item.book.stock}",
        )

    item.quantity = datos.quantity
    db.commit()
    return ver_carrito(user_id, db)

@app.delete(
    "/users/{user_id}/cart/items/{item_id}",
    response_model=ShoppingCartResponse,
    tags=["Tienda y Pedidos"],
)
def quitar_libro_del_carrito(
    user_id: int,
    item_id: int,
    db: Session = Depends(obtener_sesion),
):
    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    item = next((i for i in carrito.items if i.id == item_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail="Artículo no encontrado en el carrito")

    db.delete(item)
    db.commit()
    return ver_carrito(user_id, db)

@app.post(
    "/users/{user_id}/checkout/paypal",
    response_model=OrderResponse,
    status_code=201,
    tags=["Tienda y Pedidos"],
)
def procesar_checkout_paypal(
    user_id: int,
    datos: PayPalCheckoutRequest,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(User, user_id)
    if usuario is None or usuario.is_active != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado o inactivo")

    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    if not carrito.items:
        raise HTTPException(status_code=400, detail="El carrito de compras está vacío")

    destinatario = (datos.shipping_recipient_name or usuario.full_name).strip()
    telefono = (datos.shipping_phone or usuario.phone or "").strip()
    calle = (datos.shipping_address_line or usuario.address_line or "").strip()
    ciudad = (datos.shipping_city or usuario.city or "").strip()
    estado = (datos.shipping_state or usuario.state or "").strip()
    cp = (datos.shipping_postal_code or usuario.postal_code or "").strip()

    if not all([destinatario, telefono, calle, ciudad, estado, cp]):
        raise HTTPException(
            status_code=422,
            detail="Faltan datos completos de dirección y teléfono para el envío a domicilio",
        )

    book_ids = [item.book_id for item in carrito.items]
    libros_bloqueados = {
        b.id: b
        for b in db.scalars(
            select(Book).where(Book.id.in_(book_ids)).with_for_update()
        ).all()
    }

    subtotal = Decimal("0.00")
    for item in carrito.items:
        libro = libros_bloqueados.get(item.book_id)
        if libro is None or libro.status != "active" or libro.stock < item.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Sin stock suficiente para '{item.book.title}'",
            )
        subtotal += (Decimal(str(libro.price)) * item.quantity).quantize(Decimal("0.01"))

    shipping_cost = Decimal("0.00") if subtotal >= Decimal("500.00") else Decimal("79.00")
    total_amount = subtotal + shipping_cost
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)

    orden = Order(
        order_reference=f"EL-{ahora.strftime('%Y%m')}-{uuid.uuid4().hex[:6].upper()}",
        user_id=usuario.id,
        cart_id=carrito.id,
        status="paid",
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        total_amount=total_amount,
        currency="MXN",
        shipping_recipient_name=destinatario,
        shipping_phone=telefono,
        shipping_address_line=calle,
        shipping_city=ciudad,
        shipping_state=estado,
        shipping_postal_code=cp,
        shipping_country=datos.shipping_country,
        shipping_notes=datos.shipping_notes,
    )
    db.add(orden)
    db.flush()

    for item in carrito.items:
        libro = libros_bloqueados[item.book_id]
        line_total = (Decimal(str(libro.price)) * item.quantity).quantize(Decimal("0.01"))
        db.add(
            OrderItem(
                order_id=orden.id,
                book_id=libro.id,
                book_title_snapshot=libro.title,
                book_isbn_snapshot=libro.isbn_13,
                unit_price=libro.price,
                quantity=item.quantity,
                line_total=line_total,
            )
        )
        libro.stock -= item.quantity
        if libro.stock == 0:
            libro.status = "out_of_stock"

    pago = Payment(
        order_id=orden.id,
        provider="paypal",
        paypal_order_id=f"PP-ORD-{uuid.uuid4().hex[:12].upper()}",
        paypal_capture_id=f"PP-CAP-{uuid.uuid4().hex[:12].upper()}",
        payer_email=datos.payer_email or usuario.email,
        payer_paypal_id=f"PAYPALUSR{usuario.id:03d}MX",
        amount=total_amount,
        currency="MXN",
        status="completed",
        raw_response_summary="COMPLETED - PayPal Checkout Sandbox Mobile Capture",
        paid_at=ahora,
    )
    db.add(pago)
    db.flush()

    num_factura = f"FAC-{ahora.year}-{orden.id:05d}"
    direccion_completa = f"{calle}, {ciudad}, {estado}, C.P. {cp}, {datos.shipping_country}"
    ruta_pdf = f"storage/invoices/{ahora.year}/{ahora.month:02d}/{num_factura}.pdf"

    factura = Invoice(
        order_id=orden.id,
        payment_id=pago.id,
        invoice_number=num_factura,
        customer_name=destinatario,
        customer_email=usuario.email,
        billing_address=direccion_completa,
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        total_amount=total_amount,
        currency="MXN",
        pdf_storage_path=ruta_pdf,
        issued_at=ahora,
    )
    db.add(factura)

    carrito.status = "checked_out"
    db.commit()

    return obtener_orden(orden.id, db)

@app.get(
    "/users/{user_id}/orders",
    response_model=list[OrderResponse],
    tags=["Tienda y Pedidos"],
)
def listar_ordenes_usuario(user_id: int, db: Session = Depends(obtener_sesion)):
    stmt = (
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.payments),
            selectinload(Order.invoice),
        )
        .where(Order.user_id == user_id)
        .order_by(Order.created_at.desc())
    )
    return db.scalars(stmt).all()

@app.get("/orders/{order_id}", response_model=OrderResponse, tags=["Tienda y Pedidos"])
def obtener_orden(order_id: int, db: Session = Depends(obtener_sesion)):
    stmt = (
        select(Order)
        .options(
            selectinload(Order.items),
            selectinload(Order.payments),
            selectinload(Order.invoice),
        )
        .where(Order.id == order_id)
    )
    orden = db.scalar(stmt)
    if orden is None:
        raise HTTPException(status_code=404, detail="Orden no encontrada")
    return orden

def _paypal_obtener_token() -> tuple[str, str]:
    client_id = os.getenv("PAYPAL_CLIENT_ID", "").strip()
    client_secret = os.getenv("PAYPAL_CLIENT_SECRET", "").strip()
    base_url = os.getenv("PAYPAL_BASE_URL", "https://api-m.sandbox.paypal.com").rstrip("/")

    if not client_id or not client_secret:
        raise HTTPException(
            status_code=503,
            detail="PAYPAL_CLIENT_ID y PAYPAL_CLIENT_SECRET no están configurados en api/.env",
        )

    credenciales = base64.b64encode(f"{client_id}:{client_secret}".encode("utf-8")).decode("ascii")
    req = urllib.request.Request(
        f"{base_url}/v1/oauth2/token",
        data=b"grant_type=client_credentials",
        headers={
            "Authorization": f"Basic {credenciales}",
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
            return payload["access_token"], base_url
    except urllib.error.HTTPError as exc:
        detalle = exc.read().decode("utf-8", errors="ignore")
        raise HTTPException(status_code=502, detail=f"Error OAuth2 PayPal: {detalle}")
    except (urllib.error.URLError, TimeoutError):
        raise HTTPException(status_code=502, detail="No se pudo conectar con PayPal Sandbox")


def _validar_datos_envio(usuario: User, datos: PayPalCheckoutRequest) -> dict[str, str]:
    destinatario = (datos.shipping_recipient_name or usuario.full_name).strip()
    telefono = (datos.shipping_phone or usuario.phone or "").strip()
    calle = (datos.shipping_address_line or usuario.address_line or "").strip()
    ciudad = (datos.shipping_city or usuario.city or "").strip()
    estado = (datos.shipping_state or usuario.state or "").strip()
    cp = (datos.shipping_postal_code or usuario.postal_code or "").strip()

    if not all([destinatario, telefono, calle, ciudad, estado, cp]):
        raise HTTPException(
            status_code=422,
            detail="Faltan datos completos de dirección y teléfono para el envío a domicilio",
        )
    return {
        "destinatario": destinatario,
        "telefono": telefono,
        "calle": calle,
        "ciudad": ciudad,
        "estado": estado,
        "cp": cp,
    }

@app.get("/paypal/return", response_class=HTMLResponse, tags=["Tienda y Pedidos"])
def retorno_aprobacion_paypal():
    return """
    <!doctype html>
    <html lang="es">
    <head><meta charset="utf-8"><title>Pago Autorizado — Entre Líneas</title></head>
    <body style="font-family:sans-serif;background:#FAF7F2;color:#08245C;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
      <div style="background:#fff;border:1px solid #E5DEC9;border-radius:14px;padding:28px;max-width:440px;text-align:center;">
        <h2 style="color:#B45309;margin-top:0;">Pago autorizado en PayPal Sandbox</h2>
        <p>Ya puedes cerrar esta pestaña y regresar a la aplicación <strong>Entre Líneas</strong> para confirmar y capturar tu pedido.</p>
      </div>
    </body>
    </html>
    """

@app.get("/paypal/cancel", response_class=HTMLResponse, tags=["Tienda y Pedidos"])
def cancelacion_paypal():
    return """
    <!doctype html>
    <html lang="es">
    <head><meta charset="utf-8"><title>Pago Cancelado — Entre Líneas</title></head>
    <body style="font-family:sans-serif;background:#FAF7F2;color:#08245C;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;">
      <div style="background:#fff;border:1px solid #E5DEC9;border-radius:14px;padding:28px;max-width:440px;text-align:center;">
        <h2 style="margin-top:0;">Operación cancelada en PayPal</h2>
        <p>Cierra esta pestaña y regresa a <strong>Entre Líneas</strong> si deseas intentar nuevamente.</p>
      </div>
    </body>
    </html>
    """

@app.post(
    "/users/{user_id}/checkout/paypal/create-order",
    response_model=PayPalOrderCreateResponse,
    tags=["Tienda y Pedidos"],
)
def crear_orden_paypal_sandbox(
    user_id: int,
    datos: PayPalCheckoutRequest,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(User, user_id)
    if usuario is None or usuario.is_active != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado o inactivo")

    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    if not carrito.items:
        raise HTTPException(status_code=400, detail="El carrito de compras está vacío")

    _validar_datos_envio(usuario, datos)

    subtotal = Decimal("0.00")
    for item in carrito.items:
        libro = item.book
        if libro.status != "active" or libro.stock < item.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Sin stock suficiente para '{libro.title}' (disponible: {libro.stock})",
            )
        subtotal += (Decimal(str(libro.price)) * item.quantity).quantize(Decimal("0.01"))

    shipping_cost = Decimal("0.00") if subtotal >= Decimal("500.00") else Decimal("79.00")
    total_amount = subtotal + shipping_cost

    access_token, base_url = _paypal_obtener_token()

    order_payload = {
        "intent": "CAPTURE",
        "purchase_units": [
            {
                "reference_id": f"CART-{carrito.id}-USR-{usuario.id}",
                "description": "Compra de libros - Entre Líneas",
                "amount": {
                    "currency_code": "MXN",
                    "value": f"{total_amount:.2f}",
                    "breakdown": {
                        "item_total": {
                            "currency_code": "MXN",
                            "value": f"{subtotal:.2f}",
                        },
                        "shipping": {
                            "currency_code": "MXN",
                            "value": f"{shipping_cost:.2f}",
                        },
                    },
                },
            }
        ],
        "application_context": {
            "brand_name": "Entre Líneas",
            "landing_page": "LOGIN",
            "user_action": "PAY_NOW",
            "return_url": "http://127.0.0.1:8000/paypal/return",
            "cancel_url": "http://127.0.0.1:8000/paypal/cancel",
        },
    }

    req = urllib.request.Request(
        f"{base_url}/v2/checkout/orders",
        data=json.dumps(order_payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            pp_order = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detalle = exc.read().decode("utf-8", errors="ignore")
        raise HTTPException(status_code=502, detail=f"PayPal rechazó la orden: {detalle}")
    except (urllib.error.URLError, TimeoutError):
        raise HTTPException(status_code=502, detail="Error de red al crear orden en PayPal")

    approve_url = next(
        (link["href"] for link in pp_order.get("links", []) if link.get("rel") == "approve"),
        None,
    )
    if not approve_url:
        raise HTTPException(status_code=502, detail="PayPal no devolvió URL de aprobación")

    return PayPalOrderCreateResponse(
        paypal_order_id=pp_order["id"],
        approve_url=approve_url,
        subtotal=float(subtotal),
        shipping_cost=float(shipping_cost),
        total_amount=float(total_amount),
        currency="MXN",
    )

@app.post(
    "/users/{user_id}/checkout/paypal/capture-order",
    response_model=OrderResponse,
    status_code=201,
    tags=["Tienda y Pedidos"],
)
def capturar_orden_paypal_sandbox(
    user_id: int,
    datos: PayPalCaptureRequest,
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(User, user_id)
    if usuario is None or usuario.is_active != 1:
        raise HTTPException(status_code=404, detail="Usuario no encontrado o inactivo")

    carrito = _obtener_o_crear_carrito_activo(user_id, db)
    if not carrito.items:
        raise HTTPException(status_code=400, detail="El carrito de compras está vacío")

    envio = _validar_datos_envio(usuario, datos)

    # 1. Bloquear inventario antes de capturar el cobro
    book_ids = [item.book_id for item in carrito.items]
    libros_bloqueados = {
        b.id: b
        for b in db.scalars(
            select(Book).where(Book.id.in_(book_ids)).with_for_update()
        ).all()
    }

    subtotal = Decimal("0.00")
    for item in carrito.items:
        libro = libros_bloqueados.get(item.book_id)
        if libro is None or libro.status != "active" or libro.stock < item.quantity:
            db.rollback()
            raise HTTPException(
                status_code=400,
                detail=f"Sin stock suficiente para '{item.book.title}'",
            )
        subtotal += (Decimal(str(libro.price)) * item.quantity).quantize(Decimal("0.01"))

    shipping_cost = Decimal("0.00") if subtotal >= Decimal("500.00") else Decimal("79.00")
    total_amount = subtotal + shipping_cost

    # 2. Capturar pago real en PayPal Sandbox
    access_token, base_url = _paypal_obtener_token()
    pp_order_id = datos.paypal_order_id.strip()

    req = urllib.request.Request(
        f"{base_url}/v2/checkout/orders/{urllib.parse.quote(pp_order_id)}/capture",
        data=b"{}",
        headers={
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            capture_data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        db.rollback()
        detalle = exc.read().decode("utf-8", errors="ignore")
        if "ORDER_NOT_APPROVED" in detalle:
            raise HTTPException(
                status_code=400,
                detail="Primero inicia sesión en la ventana de PayPal Sandbox y aprueba el pago.",
            )
        raise HTTPException(status_code=400, detail=f"PayPal no pudo capturar el pago: {detalle}")
    except (urllib.error.URLError, TimeoutError):
        db.rollback()
        raise HTTPException(status_code=502, detail="Error de red al capturar pago en PayPal")

    if capture_data.get("status") != "COMPLETED":
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Estado inesperado de PayPal: {capture_data.get('status')}",
        )

    purchase_units = capture_data.get("purchase_units", [])
    captures = (
        purchase_units[0].get("payments", {}).get("captures", [])
        if purchase_units
        else []
    )
    capture_info = captures[0] if captures else {}
    capture_id = capture_info.get("id") or f"CAP-{uuid.uuid4().hex[:12].upper()}"

    payer_info = capture_data.get("payer", {})
    payer_email = payer_info.get("email_address") or datos.payer_email or usuario.email
    payer_paypal_id = payer_info.get("payer_id")

    # 3. Registrar orden, artículos, pago y factura en entre_lineas_db
    ahora = datetime.now(timezone.utc).replace(tzinfo=None)
    orden = Order(
        order_reference=f"EL-{ahora.strftime('%Y%m')}-{uuid.uuid4().hex[:6].upper()}",
        user_id=usuario.id,
        cart_id=carrito.id,
        status="paid",
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        total_amount=total_amount,
        currency="MXN",
        shipping_recipient_name=envio["destinatario"],
        shipping_phone=envio["telefono"],
        shipping_address_line=envio["calle"],
        shipping_city=envio["ciudad"],
        shipping_state=envio["estado"],
        shipping_postal_code=envio["cp"],
        shipping_country=datos.shipping_country,
        shipping_notes=datos.shipping_notes,
    )
    db.add(orden)
    db.flush()

    for item in carrito.items:
        libro = libros_bloqueados[item.book_id]
        line_total = (Decimal(str(libro.price)) * item.quantity).quantize(Decimal("0.01"))
        db.add(
            OrderItem(
                order_id=orden.id,
                book_id=libro.id,
                book_title_snapshot=libro.title,
                book_isbn_snapshot=libro.isbn_13,
                unit_price=libro.price,
                quantity=item.quantity,
                line_total=line_total,
            )
        )
        libro.stock -= item.quantity
        if libro.stock == 0:
            libro.status = "out_of_stock"

    pago = Payment(
        order_id=orden.id,
        provider="paypal",
        paypal_order_id=pp_order_id,
        paypal_capture_id=capture_id,
        payer_email=payer_email,
        payer_paypal_id=payer_paypal_id,
        amount=total_amount,
        currency="MXN",
        status="completed",
        raw_response_summary=f"COMPLETED - PayPal Sandbox Capture ({capture_id})"[:500],
        paid_at=ahora,
    )
    db.add(pago)
    db.flush()

    num_factura = f"FAC-{ahora.year}-{orden.id:05d}"
    direccion_completa = (
        f"{envio['calle']}, {envio['ciudad']}, {envio['estado']}, "
        f"C.P. {envio['cp']}, {datos.shipping_country}"
    )
    ruta_pdf = f"storage/invoices/{ahora.year}/{ahora.month:02d}/{num_factura}.pdf"

    factura = Invoice(
        order_id=orden.id,
        payment_id=pago.id,
        invoice_number=num_factura,
        customer_name=envio["destinatario"],
        customer_email=usuario.email,
        billing_address=direccion_completa,
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        total_amount=total_amount,
        currency="MXN",
        pdf_storage_path=ruta_pdf,
        issued_at=ahora,
    )
    db.add(factura)

    carrito.status = "checked_out"
    db.commit()

    return obtener_orden(orden.id, db)