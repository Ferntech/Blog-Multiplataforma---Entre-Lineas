# Entre Líneas — API REST (FastAPI)

Servicio backend desarrollado exclusivamente en **Python** con **FastAPI**, **SQLAlchemy 2.0** y **Pydantic v2** para alimentar la aplicación móvil/web en Flutter sobre la base de datos `entre_lineas_db`.

## Alcance y decisiones de diseño

- **Sin sesiones ni tokens CSRF:** A diferencia de la aplicación web PHP, la API opera sin cookies de sesión ni tokens CSRF, validando la identidad y estado activo (`is_active == 1`) del usuario mediante su `user_id`.
- **Alcance reducido al lector:** Se excluyen los módulos administrativos, de moderación e importación (`users`, `manage_books`, `manage_authors`, `posts` administrativos), exponiendo únicamente lectura de catálogo/reseñas y las acciones interactivas del lector.
- **Compatibilidad de contraseñas PHP ↔ Python:** Normaliza hashes bcrypt generados por `password_hash()` de PHP (`$2y$`) a `$2b$` antes de verificar con `pwdlib`, permitiendo iniciar sesión con las mismas cuentas registradas en la web.
- **CORS habilitado para Flutter Web (Chrome):** Permite peticiones desde cualquier puerto local en `http://localhost:*` y `http://127.0.0.1:*`.

---

## Estructura del directorio `api/`

```text
api/
├── database.py     # Configuración del motor SQLAlchemy (mysql+pymysql) y sesión
├── models.py       # Mapeo ORM de las tablas de entre_lineas_db
├── schemas.py      # Modelos Pydantic de entrada y salida JSON
├── main.py         # Definición de endpoints, proxy Giphy y checkout transaccional
├── .env            # Variables de entorno locales (no versionado)
└── README.md       # Documentación de la API
```

---

## Instalación y configuración

### 1. Requisitos previos

- Python 3.11 o superior.
- Acceso a la base de datos MySQL/MariaDB `entre_lineas_db`.
- Clave de API de **Giphy Developers** (para búsqueda de GIFs y stickers en comentarios).

### 2. Entorno virtual y dependencias

```bash
cd api
python -m venv .venv
source .venv/bin/activate        # En Windows: .venv\Scripts\activate
pip install fastapi "uvicorn[standard]" sqlalchemy pymysql pydantic "pwdlib[bcrypt]" python-dotenv
```

### 3. Variables de entorno (`api/.env`)

Crea el archivo `api/.env` con las credenciales de tu servidor MySQL y tu clave de Giphy:

```env
DB_USER=root
DB_PASSWORD=tu_password
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=entre_lineas_db
GIPHY_API_KEY=tu_clave_de_giphy
```

### 4. Ejecución del servidor

```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

La documentación interactiva queda disponible en `http://127.0.0.1:8000/docs`.

---

## Endpoints disponibles

### Estado y Autenticación

| Método | Ruta                              | Descripción                                                                             |
| :----- | :-------------------------------- | :-------------------------------------------------------------------------------------- |
| `GET`  | `/`                               | Verifica el estado operativo de la API y la conexión con `entre_lineas_db`.             |
| `POST` | `/auth/login` (alias `/login`)    | Autentica correo y contraseña (compatible con hashes `$2y$` de PHP y `$2b$` de Python). |
| `POST` | `/auth/register` (alias `/users`) | Registra una nueva cuenta con rol `reader` en `users`.                                  |

### Perfil y Comunidad

| Método | Ruta               | Descripción                                                                |
| :----- | :----------------- | :------------------------------------------------------------------------- |
| `GET`  | `/users/contacts`  | Lista miembros activos para iniciar conversaciones privadas.               |
| `GET`  | `/users/{user_id}` | Obtiene el perfil del usuario junto con su puntuación acumulada (`karma`). |
| `PUT`  | `/users/{user_id}` | Actualiza datos personales, biografía y dirección predeterminada de envío. |

### Catálogo de Libros

| Método | Ruta               | Descripción                                                                                      |
| :----- | :----------------- | :----------------------------------------------------------------------------------------------- |
| `GET`  | `/tags`            | Lista las etiquetas literarias disponibles.                                                      |
| `GET`  | `/books`           | Explora libros activos o agotados con filtros `search` (título, autor, editorial, ISBN) y `tag`. |
| `GET`  | `/books/{book_id}` | Devuelve la ficha detallada de un libro con sus autores y etiquetas.                             |

### Reseñas, Votos y Comentarios con Giphy

| Método | Ruta                             | Descripción                                                                                             |
| :----- | :------------------------------- | :------------------------------------------------------------------------------------------------------ |
| `GET`  | `/blog-posts`                    | Lista reseñas publicadas con su libro vinculado, puntaje de votos, `user_vote` y conteo de comentarios. |
| `GET`  | `/blog-posts/{post_id}`          | Obtiene el contenido completo de una reseña y la reputación del autor.                                  |
| `POST` | `/blog-posts/{post_id}/vote`     | Registra, actualiza o retira (`-1`, `0`, `1`) el voto del usuario bloqueando autovotos.                 |
| `GET`  | `/blog-posts/{post_id}/comments` | Lista los comentarios visibles de una reseña junto con sus GIFs/stickers adjuntos.                      |
| `POST` | `/blog-posts/{post_id}/comments` | Publica un comentario de texto, un GIF/sticker de Giphy o ambos.                                        |
| `GET`  | `/giphy/search`                  | Proxy hacia la API de Giphy (`type=gif` o `type=sticker`) para evitar bloqueos CORS en navegador.       |

### Mensajería Directa

| Método | Ruta                                          | Descripción                                                                           |
| :----- | :-------------------------------------------- | :------------------------------------------------------------------------------------ |
| `GET`  | `/users/{user_id}/conversations`              | Agrupa hilos activos por interlocutor con último mensaje y contador de no leídos.     |
| `GET`  | `/users/{user_id}/messages?with_user_id={id}` | Obtiene el historial del chat y marca como leídos (`read_at`) los mensajes recibidos. |
| `POST` | `/messages`                                   | Envía un mensaje privado entre dos usuarios distintos.                                |

### Carrito de Compras, Checkout y Pedidos

| Método   | Ruta                                    | Descripción                                                                                                                         |
| :------- | :-------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------- |
| `GET`    | `/users/{user_id}/cart`                 | Consulta o inicializa el carrito activo con cálculo de envío (`$0` si subtotal >= `$500 MXN`, `$79 MXN` en caso contrario).         |
| `POST`   | `/users/{user_id}/cart/items`           | Agrega ejemplares al carrito validando existencias en inventario.                                                                   |
| `PUT`    | `/users/{user_id}/cart/items/{item_id}` | Actualiza la cantidad de un artículo en el carrito.                                                                                 |
| `DELETE` | `/users/{user_id}/cart/items/{item_id}` | Elimina un artículo del carrito.                                                                                                    |
| `POST`   | `/users/{user_id}/checkout/paypal`      | Bloquea filas de inventario (`FOR UPDATE`), descuenta stock y genera registros en `orders`, `order_items`, `payments` e `invoices`. |
| `GET`    | `/users/{user_id}/orders`               | Lista el historial de pedidos del usuario con sus líneas de compra y folio de factura.                                              |
| `GET`    | `/orders/{order_id}`                    | Consulta el detalle completo de un pedido específico.                                                                               |
