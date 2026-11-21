# Entre Líneas — Aplicación Cliente (Flutter)

Cliente multiplataforma desarrollado en **Flutter** (probado en **Google Chrome**) que consume la API REST de **FastAPI** para ofrecer las funcionalidades esenciales de lectura, comunidad y compra de libros de **Entre Líneas**.

## Alcance funcional

A diferencia de la versión web (que admite visitantes anónimos y paneles de administración), esta aplicación está diseñada exclusivamente para **usuarios autenticados**:

- **Acceso autenticado obligatorio:** Inicio de sesión y registro de lectores (`LoginPage`, `RegisterPage`) sin modo visitante.
- **Revista Literaria y Votos:** Exploración de reseñas con búsqueda y filtrado por etiquetas, visualización de calificación con estrellas, reputación acumulada del autor y votación positiva/negativa (`+1` / `-1`).
- **Comentarios enriquecidos con Giphy:** Lectura y redacción de comentarios con selector integrado de **GIFs y Stickers** mediante el proxy de Giphy en FastAPI.
- **Catálogo Editorial:** Búsqueda de libros por título, autor, editorial o ISBN, consulta de ficha técnica, sinopsis y reseñas asociadas.
- **Carrito y Checkout:** Sincronización del carrito persistente en base de datos, validación de stock, cálculo automático de envío gratuito a partir de `$500.00 MXN` y confirmación de compra con captura de dirección de entrega.
- **Mensajería Directa:** Bandeja de conversaciones con contador de mensajes sin leer, inicio de nuevos chats con miembros de la comunidad y lectura en hilo.
- **Perfil e Historial de Pedidos:** Edición de datos personales, dirección predeterminada de envío y consulta de órdenes con folio de comprobante.

---

## Identidad visual

La interfaz mantiene coherencia estética con la plataforma web mediante `AppTheme` (`lib/theme/app_theme.dart`):

- **Paleta editorial:** Superficie papel crema (`#FAF7F2`), tinta azul marino (`#08245C`) y acentos ámbar/ocre (`#B45309`).
- **Fondo de autenticación compartido:** Utiliza `assets/images/login_background.jpg` en `AuthBackground` con filtro de contraste para las vistas de acceso y registro.

---

## Estructura del proyecto (`flutter/`)

```text
flutter/
├── assets/
│   └── images/
│       └── login_background.jpg    # Imagen de fondo compartida con la versión web
├── lib/
│   ├── main.dart                   # Punto de entrada, rutas y aplicación de AppTheme
│   ├── theme/
│   │   └── app_theme.dart          # Paleta AppColors y configuración Material 3
│   ├── models/
│   │   ├── book_model.dart         # Modelos de libro, autor y etiqueta
│   │   ├── cart_model.dart         # Modelos de carrito y líneas de compra
│   │   ├── comentario_model.dart   # Modelos de comentario y adjuntos Giphy
│   │   ├── message_model.dart      # Modelos de conversación y mensaje privado
│   │   ├── order_model.dart        # Modelos de pedido, artículos y factura
│   │   ├── post_model.dart         # Modelo de reseña literaria con votos
│   │   └── user_model.dart         # Modelo de usuario y resumen de perfil
│   ├── services/
│   │   ├── auth_service.dart       # Login y registro contra FastAPI
│   │   ├── book_service.dart       # Consulta de catálogo y etiquetas
│   │   ├── cart_service.dart       # Operaciones de carrito y checkout
│   │   ├── comentario_service.dart # Listado/envío de comentarios y búsqueda Giphy
│   │   ├── message_service.dart    # Bandeja de mensajes e hilos privados
│   │   ├── order_service.dart      # Consulta de historial de pedidos
│   │   ├── post_service.dart       # Listado/detalle de reseñas y emisión de votos
│   │   ├── session_manager.dart    # Estado global del usuario activo y contadores
│   │   └── user_service.dart       # Consulta y edición de perfil y contactos
│   ├── screens/
│   │   ├── book_detail_page.dart   # Ficha de libro y compra directa
│   │   ├── cart_page.dart          # Gestión del carrito de compras
│   │   ├── catalog_page.dart       # Explorador del catálogo editorial
│   │   ├── chat_page.dart          # Hilo de conversación privada
│   │   ├── checkout_page.dart      # Formulario de envío y confirmación de pago
│   │   ├── conversations_page.dart # Bandeja de entrada de mensajería
│   │   ├── dashboard_page.dart     # Feed principal de reseñas literarias
│   │   ├── login_page.dart         # Pantalla de inicio de sesión
│   │   ├── main_shell.dart         # Contenedor con NavigationBar y acceso al carrito
│   │   ├── orders_page.dart        # Historial de compras del usuario
│   │   ├── post_detail_page.dart   # Lectura de reseña, votos y comentarios Giphy
│   │   ├── profile_page.dart       # Edición de perfil y dirección de envío
│   │   └── register_page.dart      # Registro de nuevos lectores
│   └── widgets/
│       ├── auth_background.dart    # Fondo con login_background.jpg
│       ├── auth_card.dart          # Contenedor estilizado para login/registro
│       ├── category_chip.dart      # Chip de filtrado por etiquetas
│       ├── custom_text_field.dart  # Campo de texto con estilo editorial
│       ├── post_card.dart          # Tarjeta de vista previa de reseña
│       └── primary_button.dart     # Botón principal de acción
├── pubspec.yaml                    # Dependencias (http, material_ui, cupertino_icons)
└── README.md                       # Documentación de la app móvil
```

---

## Instalación y ejecución en Chrome

### 1. Requisitos previos

- Flutter SDK con soporte para Dart `^3.6.1`.
- Google Chrome instalado.
- Servidor backend de FastAPI ejecutándose en `http://127.0.0.1:8000`.

### 2. Instalar dependencias y ejecutar

```bash
cd flutter
flutter pub get
flutter run -d chrome
```

> **Nota:** Si modificas la dirección o puerto del backend, actualiza la constante `baseUrl` en los archivos dentro de `lib/services/`.