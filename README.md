# Entre Líneas — Librería y revista literaria

**Entre Líneas** es una plataforma multiplataforma que integra una revista literaria colaborativa con una librería de comercio electrónico. El entorno comparte una única base de datos relacional (`entre_lineas_db`) en MySQL/MariaDB y se compone de tres módulos independientes:

1. **Plataforma Web (Raíz PHP):** Aplicación completa con renderizado en servidor, panel administrativo y editorial, pasarela **PayPal REST API v2 (Sandbox)** y emisión de comprobantes **PDF**.
2. **API REST (`api/`):** Servicio backend sin estado desarrollado en **Python (FastAPI + SQLAlchemy)** que expone los flujos esenciales de lectura, interacción comunitaria y compras para el cliente móvil.
3. **Aplicación Móvil / Web (`flutter/`):** Cliente ligero construido en **Flutter** con acceso autenticado obligatorio, enfocado en la lectura de reseñas, comentarios con Giphy, mensajería directa y compras.

---

## Arquitectura del ecosistema

```text
┌────────────────────────┐      ┌────────────────────────┐
│   Aplicación Web PHP   │      │    Cliente Flutter     │
│ (Lector + Editorial +  │      │  (Acceso Autenticado   │
│  Admin + PayPal + PDF) │      │    para Lectores)      │
└───────────┬────────────┘      └───────────┬────────────┘
            │                               │ HTTP / JSON
            │ PDO                           ▼
            │                   ┌────────────────────────┐
            │                   │    FastAPI (Python)    │
            │                   │   api/ (REST + CORS)   │
            │                   └───────────┬────────────┘
            │                               │ SQLAlchemy (PyMySQL)
            ▼                               ▼
     ┌─────────────────────────────────────────────┐
     │       MySQL 8.0 / MariaDB 10.6+ (utf8mb4)   │
     │              entre_lineas_db                │
     └─────────────────────────────────────────────┘
```

---

## Estructura del repositorio

```text
.
├── api/                        # Backend REST en Python (FastAPI)
│   ├── database.py             # Conexión SQLAlchemy + PyMySQL vía .env
│   ├── models.py               # Modelos ORM de entre_lineas_db
│   ├── schemas.py              # Esquemas de validación Pydantic v2
│   ├── main.py                 # Rutas REST, CORS y lógica transaccional
│   └── README.md               # Documentación específica de la API
├── flutter/                    # Aplicación cliente en Flutter
│   ├── assets/images/          # Recursos gráficos (login_background.jpg)
│   ├── lib/                    # Código fuente Dart (modelos, servicios, pantallas, temas)
│   ├── pubspec.yaml            # Dependencias y configuración de assets
│   └── README.md               # Documentación específica de Flutter
├── .env_example                # Archivo con credenciales de ejemplo (renombrar a .env y añadir credenciales correspondientes)
├── db_schema.sql               # Estructura completa de entre_lineas_db
├── .gitignore                  # Exclusión de credenciales, dependencias y artefactos locales
└── README.md                   # Documentación general del proyecto
```

---

## Modelo de base de datos compartido (`entre_lineas_db`)

El esquema relacional definido en `storage/sql/db_schema.sql` soporta simultáneamente la operación web y móvil dividido en dos dominios:

- **Dominio Editorial y Comunidad:**
  - `users`: Cuentas con roles (`reader`, `author`, `admin`), hashes bcrypt compatibles entre PHP y Python, biografía y dirección predeterminada de envío.
  - `authors`, `books`, `book_authors`, `tags`, `book_tags`: Catálogo editorial con `isbn_10`, `isbn_13`, existencias (`stock`), precio y estado (`draft`, `active`, `out_of_stock`, `archived`).
  - `blog_posts` y `blog_post_tags`: Reseñas literarias vinculadas directamente a una obra del catálogo (`book_id`) y a su reseñador (`author_id`).
  - `blog_votes`: Sistema de votación positiva/negativa (`+1` / `-1`) por usuario y reseña, con cálculo de reputación acumulada para los autores.
  - `comments` y `comment_media`: Comentarios en reseñas con soporte para texto y adjuntos multimedia (GIFs y stickers de Giphy).
  - `private_messages`: Mensajería directa entre miembros con control de lectura (`read_at`) y borrado lógico independiente por participante (`sender_deleted_at`, `recipient_deleted_at`).

- **Dominio de Comercio Electrónico:**
  - `shopping_carts` y `cart_items`: Carritos persistentes sincronizados en base de datos entre plataformas.
  - `orders` y `order_items`: Pedidos con referencia única (`EL-...`), cálculo de envío (envío gratuito en compras a partir de `$500.00 MXN`; `$79.00 MXN` en pedidos menores) y snapshots inmutables de título, ISBN y precio.
  - `payments` e `invoices`: Auditoría de pagos mediante PayPal Sandbox y folios de comprobante (`FAC-YYYY-00001`).

---

## Orden de despliegue local

1. **Base de datos:** Crea la base de datos `entre_lineas_db` en MySQL 8.0 / MariaDB 10.6+ con cotejamiento `utf8mb4_unicode_ci` e importa `storage/sql/db_schema.sql`. *Las credenciales por defecto son user: admin@entrelineas.com password:fer123456
2. **API FastAPI:** Configura `api/.env` y levanta el servidor Uvicorn en `http://127.0.0.1:8000` (ver `api/README.md`).
3. **Cliente Flutter:** Instala paquetes con `flutter pub get` y ejecuta `flutter run -d chrome` (ver `flutter/README.md`).
