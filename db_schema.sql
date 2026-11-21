CREATE DATABASE IF NOT EXISTS `entre_lineas_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `entre_lineas_db`;

SET NAMES utf8mb4;
SET @OLD_TIME_ZONE=@@TIME_ZONE;
SET TIME_ZONE='+00:00';
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO';

-- 1. Tabla: users (Usuarios, perfiles, roles y dirección predeterminada)
CREATE TABLE `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('reader','author','admin') NOT NULL DEFAULT 'reader',
  `avatar_url` varchar(1000) DEFAULT NULL,
  `bio` varchar(500) DEFAULT NULL,
  `phone` varchar(25) DEFAULT NULL,
  `address_line` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `postal_code` varchar(20) DEFAULT NULL,
  `country` varchar(80) NOT NULL DEFAULT 'México',
  `is_active` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `updated_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_role_active` (`role`,`is_active`,`full_name`),
  KEY `idx_users_updated_by` (`updated_by`),
  CONSTRAINT `fk_users_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_users_is_active` CHECK (`is_active` in (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Tabla: authors (Autores literarios con metadatos y foto de OpenLibrary)
CREATE TABLE `authors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(160) NOT NULL,
  `slug` varchar(180) NOT NULL,
  `openlibrary_key` varchar(64) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `photo_url` varchar(1000) DEFAULT NULL,
  `birth_year` smallint(5) unsigned DEFAULT NULL,
  `nationality` varchar(80) DEFAULT NULL,
  `is_active` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_authors_slug` (`slug`),
  UNIQUE KEY `uq_authors_openlibrary_key` (`openlibrary_key`),
  KEY `idx_authors_name` (`name`),
  KEY `idx_authors_active_name` (`is_active`,`name`),
  CONSTRAINT `chk_authors_is_active` CHECK (`is_active` in (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Tabla: books (Catálogo unificado de libros reseñables e inventario de tienda)
CREATE TABLE `books` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `subtitle` varchar(250) DEFAULT NULL,
  `slug` varchar(220) NOT NULL,
  `isbn_10` varchar(10) DEFAULT NULL,
  `isbn_13` varchar(13) NOT NULL,
  `openlibrary_work_key` varchar(64) DEFAULT NULL,
  `openlibrary_edition_key` varchar(64) DEFAULT NULL,
  `publisher` varchar(150) DEFAULT NULL,
  `published_year` smallint(5) unsigned DEFAULT NULL,
  `page_count` smallint(5) unsigned DEFAULT NULL,
  `language` varchar(10) NOT NULL DEFAULT 'es',
  `cover_url` varchar(1000) DEFAULT NULL,
  `synopsis` text DEFAULT NULL,
  `price` decimal(10,2) unsigned NOT NULL,
  `stock` int(10) unsigned NOT NULL DEFAULT 0,
  `status` enum('draft','active','out_of_stock','archived') NOT NULL DEFAULT 'draft',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_books_slug` (`slug`),
  UNIQUE KEY `uq_books_isbn10` (`isbn_10`),
  UNIQUE KEY `uq_books_isbn13` (`isbn_13`),
  KEY `idx_books_title` (`title`),
  KEY `idx_books_status_title` (`status`,`title`),
  KEY `idx_books_price` (`price`),
  CONSTRAINT `chk_books_price` CHECK (`price` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Tabla: book_authors (Relación N:M protegida entre libros y autores)
CREATE TABLE `book_authors` (
  `book_id` int(10) unsigned NOT NULL,
  `author_id` int(10) unsigned NOT NULL,
  `author_order` tinyint(3) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`book_id`,`author_id`),
  KEY `idx_book_authors_author` (`author_id`,`book_id`),
  CONSTRAINT `fk_book_authors_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_book_authors_author` FOREIGN KEY (`author_id`) REFERENCES `authors` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Tabla: tags (Taxonomía compartida para catálogo de libros y entradas del blog)
CREATE TABLE `tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `slug` varchar(90) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tags_name` (`name`),
  UNIQUE KEY `uq_tags_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Tabla: book_tags (Clasificación temática de libros para filtros en tienda)
CREATE TABLE `book_tags` (
  `book_id` int(10) unsigned NOT NULL,
  `tag_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`book_id`,`tag_id`),
  KEY `idx_book_tags_tag` (`tag_id`,`book_id`),
  CONSTRAINT `fk_book_tags_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_book_tags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Tabla: blog_posts (Reseñas editoriales del staff vinculadas a un libro)
CREATE TABLE `blog_posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `author_id` int(10) unsigned NOT NULL,
  `book_id` int(10) unsigned NOT NULL,
  `title` varchar(180) NOT NULL,
  `slug` varchar(210) NOT NULL,
  `excerpt` varchar(400) DEFAULT NULL,
  `content` mediumtext NOT NULL,
  `rating` tinyint(3) unsigned NOT NULL,
  `status` enum('draft','published','archived') NOT NULL DEFAULT 'draft',
  `published_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_blog_posts_slug` (`slug`),
  KEY `idx_blog_posts_author_date` (`author_id`,`created_at`),
  KEY `idx_blog_posts_book_status_date` (`book_id`,`status`,`published_at`),
  KEY `idx_blog_posts_status_published` (`status`,`published_at`),
  CONSTRAINT `fk_blog_posts_author` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_blog_posts_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_blog_posts_rating` CHECK (`rating` between 1 and 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Tabla: blog_post_tags (Etiquetas asociadas a entradas del blog)
CREATE TABLE `blog_post_tags` (
  `post_id` int(10) unsigned NOT NULL,
  `tag_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`post_id`,`tag_id`),
  KEY `idx_blog_post_tags_tag` (`tag_id`,`post_id`),
  CONSTRAINT `fk_blog_post_tags_post` FOREIGN KEY (`post_id`) REFERENCES `blog_posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_blog_post_tags_tag` FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Tabla: blog_votes (Votos positivos/negativos por usuario en reseñas)
CREATE TABLE `blog_votes` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `post_id` int(10) unsigned NOT NULL,
  `vote_value` tinyint(4) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_blog_votes_user_post` (`user_id`,`post_id`),
  KEY `idx_blog_votes_post_value` (`post_id`,`vote_value`),
  CONSTRAINT `fk_blog_votes_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_blog_votes_post` FOREIGN KEY (`post_id`) REFERENCES `blog_posts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_blog_votes_value` CHECK (`vote_value` in (-1,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Tabla: comments (Comentarios de la comunidad con moderación trazable)
CREATE TABLE `comments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `post_id` int(10) unsigned NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `content` varchar(3000) NOT NULL,
  `status` enum('visible','hidden','deleted') NOT NULL DEFAULT 'visible',
  `moderated_by` int(10) unsigned DEFAULT NULL,
  `moderated_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_comments_post_status_date` (`post_id`,`status`,`created_at`),
  KEY `idx_comments_user_date` (`user_id`,`created_at`),
  KEY `idx_comments_moderated_by` (`moderated_by`),
  CONSTRAINT `fk_comments_post` FOREIGN KEY (`post_id`) REFERENCES `blog_posts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_comments_moderated_by` FOREIGN KEY (`moderated_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Tabla: comment_media (Adjuntos GIF/Stickers vía API gratuita de GIPHY)
CREATE TABLE `comment_media` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `comment_id` int(10) unsigned NOT NULL,
  `provider` enum('giphy') NOT NULL DEFAULT 'giphy',
  `media_type` enum('gif','sticker') NOT NULL DEFAULT 'gif',
  `giphy_id` varchar(64) NOT NULL,
  `media_url` varchar(1000) NOT NULL,
  `preview_url` varchar(1000) DEFAULT NULL,
  `width` smallint(5) unsigned DEFAULT NULL,
  `height` smallint(5) unsigned DEFAULT NULL,
  `alt_text` varchar(200) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_comment_media_comment` (`comment_id`),
  KEY `idx_comment_media_giphy_id` (`giphy_id`),
  CONSTRAINT `fk_comment_media_comment` FOREIGN KEY (`comment_id`) REFERENCES `comments` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. Tabla: private_messages (Mensajería directa con borrado lógico por bandeja)
CREATE TABLE `private_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sender_id` int(10) unsigned NOT NULL,
  `recipient_id` int(10) unsigned NOT NULL,
  `content` varchar(3000) NOT NULL,
  `sent_at` datetime NOT NULL DEFAULT current_timestamp(),
  `read_at` datetime DEFAULT NULL,
  `sender_deleted_at` datetime DEFAULT NULL,
  `recipient_deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_private_messages_inbox` (`recipient_id`,`recipient_deleted_at`,`sent_at`),
  KEY `idx_private_messages_outbox` (`sender_id`,`sender_deleted_at`,`sent_at`),
  KEY `idx_private_messages_thread_fwd` (`sender_id`,`recipient_id`,`sent_at`),
  KEY `idx_private_messages_thread_rev` (`recipient_id`,`sender_id`,`sent_at`),
  CONSTRAINT `fk_private_messages_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_private_messages_recipient` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER `trg_private_messages_before_insert`
BEFORE INSERT ON `private_messages`
FOR EACH ROW
BEGIN
  IF NEW.`sender_id` = NEW.`recipient_id` THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'sender_id and recipient_id cannot be the same user';
  END IF;
END$$

CREATE TRIGGER `trg_private_messages_before_update`
BEFORE UPDATE ON `private_messages`
FOR EACH ROW
BEGIN
  IF NEW.`sender_id` = NEW.`recipient_id` THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'sender_id and recipient_id cannot be the same user';
  END IF;
END$$
DELIMITER ;

-- 13. Tabla: shopping_carts (Carritos de compra con unicidad de carrito activo)
CREATE TABLE `shopping_carts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `status` enum('active','checked_out','abandoned') NOT NULL DEFAULT 'active',
  `active_user_id` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_shopping_carts_one_active` (`active_user_id`),
  KEY `idx_shopping_carts_user_status` (`user_id`,`status`),
  CONSTRAINT `fk_shopping_carts_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER `trg_shopping_carts_before_insert`
BEFORE INSERT ON `shopping_carts`
FOR EACH ROW
BEGIN
  SET NEW.`active_user_id` = IF(NEW.`status` = 'active', NEW.`user_id`, NULL);
END$$

CREATE TRIGGER `trg_shopping_carts_before_update`
BEFORE UPDATE ON `shopping_carts`
FOR EACH ROW
BEGIN
  SET NEW.`active_user_id` = IF(NEW.`status` = 'active', NEW.`user_id`, NULL);
END$$
DELIMITER ;

-- 14. Tabla: cart_items (Libros agregados al carrito de compras)
CREATE TABLE `cart_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cart_id` int(10) unsigned NOT NULL,
  `book_id` int(10) unsigned NOT NULL,
  `quantity` int(10) unsigned NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cart_items_cart_book` (`cart_id`,`book_id`),
  KEY `idx_cart_items_book` (`book_id`),
  CONSTRAINT `fk_cart_items_cart` FOREIGN KEY (`cart_id`) REFERENCES `shopping_carts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_cart_items_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_cart_items_quantity` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. Tabla: orders (Pedidos con snapshot de envío y trazabilidad de estado)
CREATE TABLE `orders` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_reference` varchar(32) NOT NULL,
  `user_id` int(10) unsigned NOT NULL,
  `cart_id` int(10) unsigned DEFAULT NULL,
  `status` enum('pending_payment','paid','preparing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending_payment',
  `subtotal` decimal(10,2) unsigned NOT NULL,
  `shipping_cost` decimal(10,2) unsigned NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) unsigned NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MXN',
  `shipping_recipient_name` varchar(120) NOT NULL,
  `shipping_phone` varchar(25) NOT NULL,
  `shipping_address_line` varchar(255) NOT NULL,
  `shipping_city` varchar(100) NOT NULL,
  `shipping_state` varchar(100) NOT NULL,
  `shipping_postal_code` varchar(20) NOT NULL,
  `shipping_country` varchar(80) NOT NULL DEFAULT 'México',
  `shipping_notes` varchar(300) DEFAULT NULL,
  `tracking_number` varchar(80) DEFAULT NULL,
  `shipped_at` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `status_updated_by` int(10) unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_orders_reference` (`order_reference`),
  KEY `idx_orders_user_date` (`user_id`,`created_at`),
  KEY `idx_orders_status_date` (`status`,`created_at`),
  KEY `fk_orders_cart` (`cart_id`),
  KEY `idx_orders_status_updated_by` (`status_updated_by`),
  CONSTRAINT `fk_orders_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_orders_cart` FOREIGN KEY (`cart_id`) REFERENCES `shopping_carts` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_orders_status_updated_by` FOREIGN KEY (`status_updated_by`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. Tabla: order_items (Detalle inmutable de libros comprados por orden)
CREATE TABLE `order_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `book_id` int(10) unsigned NOT NULL,
  `book_title_snapshot` varchar(200) NOT NULL,
  `book_isbn_snapshot` varchar(13) NOT NULL,
  `unit_price` decimal(10,2) unsigned NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `line_total` decimal(10,2) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_items_order` (`order_id`),
  KEY `idx_order_items_book` (`book_id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_order_items_book` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_order_items_quantity` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. Tabla: payments (Transacciones mediante PayPal protegidas contra borrado)
CREATE TABLE `payments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `provider` enum('paypal') NOT NULL DEFAULT 'paypal',
  `paypal_order_id` varchar(64) NOT NULL,
  `paypal_capture_id` varchar(64) DEFAULT NULL,
  `payer_email` varchar(150) DEFAULT NULL,
  `payer_paypal_id` varchar(64) DEFAULT NULL,
  `amount` decimal(10,2) unsigned NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MXN',
  `status` enum('created','approved','completed','failed','refunded') NOT NULL DEFAULT 'created',
  `raw_response_summary` varchar(500) DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payments_paypal_order_id` (`paypal_order_id`),
  UNIQUE KEY `uq_payments_paypal_capture_id` (`paypal_capture_id`),
  KEY `idx_payments_order_status` (`order_id`,`status`),
  CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. Tabla: invoices (Comprobantes electrónicos inmutables generados tras el pago)
CREATE TABLE `invoices` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `payment_id` int(10) unsigned NOT NULL,
  `invoice_number` varchar(32) NOT NULL,
  `customer_name` varchar(120) NOT NULL,
  `customer_email` varchar(150) NOT NULL,
  `billing_address` varchar(350) NOT NULL,
  `subtotal` decimal(10,2) unsigned NOT NULL,
  `shipping_cost` decimal(10,2) unsigned NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) unsigned NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MXN',
  `pdf_storage_path` varchar(500) NOT NULL,
  `issued_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_invoices_order` (`order_id`),
  UNIQUE KEY `uq_invoices_payment` (`payment_id`),
  UNIQUE KEY `uq_invoices_number` (`invoice_number`),
  CONSTRAINT `fk_invoices_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_invoices_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- DATOS DE MUESTRA
-- ============================================================================

INSERT INTO `users` (`id`, `full_name`, `email`, `password_hash`, `role`, `avatar_url`, `bio`, `phone`, `address_line`, `city`, `state`, `postal_code`, `country`, `is_active`, `updated_by`, `created_at`, `updated_at`) VALUES
(1, 'Admin EntreLineas', 'admin@entrelineas.com', '$argon2id$v=19$m=65536,t=4,p=1$NFdIN2VMaEptZ1NGV2hXVg$vwxQq1wjTRgzXDiOKr6tL75nByGfr2vBn5NjBBUN0kQ', 'admin', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80', 'Editor en jefe y coordinador de catálogo en Entre Líneas. Lector de narrativa latinoamericana y ensayo breve.', '4421983410', 'Av. Universidad 245, Col. Centro', 'Santiago de Querétaro', 'Querétaro', '76000', 'México', 1, NULL, '2026-10-15 10:00:00', '2026-11-11 20:53:46'),
(2, 'Alejandra Zanella', 'ale@gmail.com', '$argon2id$v=19$m=65536,t=4,p=1$ZVQ0V3dlYkkzeS9Za2JrUQ$u4C76DcBNoJ95YXseuidgfhOPFNrpaUo27K27VmY53U', 'author', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80', 'Reseñista literaria del equipo Entre Líneas. Especialista en realismo mágico, cuento corto y novela contemporánea.', '4423109821', 'Calle Hidalgo 88, Int. 4, Col. Centro Histórico', 'Santiago de Querétaro', 'Querétaro', '76000', 'México', 1, NULL, '2026-10-15 10:15:00', '2026-11-11 20:54:18'),
(3, 'Pedro Hernández', 'pedro@gmail.com', '$argon2id$v=19$m=65536,t=4,p=1$UGloaG5UMnFIR0ozRGVaVw$+ndQ7O+NfnFNkx1up6wxXfJ5w1BetB1+LAiuHMDtV84', 'reader', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80', 'Lector nocturno aficionado a la ciencia ficción, el misterio y las ediciones anotadas.', '5548921104', 'Calle Colima 192, Depto. 302, Col. Roma Norte', 'Ciudad de México', 'Ciudad de México', '06700', 'México', 1, NULL, '2026-10-18 14:20:00', '2026-11-11 20:54:30'),
(4, 'Mariana Valdés', 'mariana.valdes@entrelineas.mx', '$argon2id$v=19$m=65536,t=4,p=1$NFdIN2VMaEptZ1NGV2hXVg$vwxQq1wjTRgzXDiOKr6tL75nByGfr2vBn5NjBBUN0kQ', 'author', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=300&q=80', 'Librera y curadora de novedades editoriales. Escribe guías de lectura para clubes de libro.', '3318456620', 'Av. Chapultepec Sur 410, Col. Americana', 'Guadalajara', 'Jalisco', '44160', 'México', 1, NULL, '2026-10-20 09:30:00', '2026-11-12 11:10:00'),
(5, 'Sofía Mendoza', 'sofia.mendoza@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$ZVQ0V3dlYkkzeS9Za2JrUQ$u4C76DcBNoJ95YXseuidgfhOPFNrpaUo27K27VmY53U', 'reader', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80', 'Coleccionista de clásicos hispanoamericanos y estudiante de letras modernas.', '8124509912', 'Calzada del Valle 315, Col. Del Valle', 'San Pedro Garza García', 'Nuevo León', '66220', 'México', 1, NULL, '2026-10-25 18:05:00', '2026-11-10 16:40:00'),
(6, 'Diego Ramírez', 'diego.ramirez@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$UGloaG5UMnFIR0ozRGVaVw$+ndQ7O+NfnFNkx1up6wxXfJ5w1BetB1+LAiuHMDtV84', 'reader', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80', 'Me gusta descubrir libros a través de reseñas honestas antes de comprarlos.', '2226190438', 'Av. Juárez 1508, Col. La Paz', 'Puebla', 'Puebla', '72160', 'México', 1, NULL, '2026-10-28 12:45:00', '2026-11-13 09:20:00'),
(7, 'Valeria Ortiz', 'valeria.ortiz@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$NFdIN2VMaEptZ1NGV2hXVg$vwxQq1wjTRgzXDiOKr6tL75nByGfr2vBn5NjBBUN0kQ', 'reader', NULL, 'Lectora de novela histórica, fantasía y crónica.', '4427812390', 'Blvd. Bernardo Quintana 4050, Col. Álamos 3a Sección', 'Santiago de Querétaro', 'Querétaro', '76160', 'México', 1, NULL, '2026-11-01 16:00:00', '2026-11-14 14:15:00'),
(8, 'Carlos Navarro', 'carlos.navarro@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$ZVQ0V3dlYkkzeS9Za2JrUQ$u4C76DcBNoJ95YXseuidgfhOPFNrpaUo27K27VmY53U', 'reader', NULL, NULL, '9992348711', 'Paseo de Montejo 480, Col. Centro', 'Mérida', 'Yucatán', '97000', 'México', 0, 1, '2026-11-02 11:10:00', '2026-11-09 08:50:00'),
(9, 'Lucía Castellanos', 'lucia.castellanos@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$NFdIN2VMaEptZ1NGV2hXVg$vwxQq1wjTRgzXDiOKr6tL75nByGfr2vBn5NjBBUN0kQ', 'reader', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80', 'Apasionada por la novela negra, el ensayo histórico y las tardes de café con un buen libro.', '4428193340', 'Av. Zaragoza 112, Col. Niños Héroes', 'Santiago de Querétaro', 'Querétaro', '76010', 'México', 1, NULL, '2026-11-04 10:25:00', '2026-11-15 18:10:00'),
(10, 'Mateo Morales', 'mateo.morales@correo.mx', '$argon2id$v=19$m=65536,t=4,p=1$UGloaG5UMnFIR0ozRGVaVw$+ndQ7O+NfnFNkx1up6wxXfJ5w1BetB1+LAiuHMDtV84', 'reader', NULL, 'Ingeniero de software en el día, lector de sagas épicas y literatura mexicana por la noche.', '5539104482', 'Av. División del Norte 1420, Col. Letrán Valle', 'Ciudad de México', 'Ciudad de México', '03650', 'México', 1, NULL, '2026-11-06 19:40:00', '2026-11-16 12:00:00');

INSERT INTO `authors` (`id`, `name`, `slug`, `openlibrary_key`, `bio`, `photo_url`, `birth_year`, `nationality`, `is_active`) VALUES
(1, 'Juan Rulfo', 'juan-rulfo', '/authors/OL198431A', 'Narrador, guionista y fotógrafo mexicano, figura fundamental de la literatura hispanoamericana del siglo XX.', 'https://covers.openlibrary.org/a/olid/OL198431A-M.jpg', 1917, 'México', 1),
(2, 'Gabriel García Márquez', 'gabriel-garcia-marquez', '/authors/OL139486A', 'Escritor y periodista colombiano, Premio Nobel de Literatura 1982 y máximo exponente del realismo mágico.', 'https://covers.openlibrary.org/a/olid/OL139486A-M.jpg', 1927, 'Colombia', 1),
(3, 'Isabel Allende', 'isabel-allende', '/authors/OL262344A', 'Escritora chilena reconocida internacionalmente por novelas que entrelazan memoria familiar e historia política.', 'https://covers.openlibrary.org/a/olid/OL262344A-M.jpg', 1942, 'Chile', 1),
(4, 'Jorge Luis Borges', 'jorge-luis-borges', '/authors/OL19857A', 'Cuentista, poeta y ensayista argentino cuya obra renovó la narrativa fantástica y filosófica universal.', 'https://covers.openlibrary.org/a/olid/OL19857A-M.jpg', 1899, 'Argentina', 1),
(5, 'Julio Cortázar', 'julio-cortazar', '/authors/OL118077A', 'Escritor argentino maestro del relato corto, la prosa poética y la experimentación narrativa.', 'https://covers.openlibrary.org/a/olid/OL118077A-M.jpg', 1914, 'Argentina', 1),
(6, 'Carlos Ruiz Zafón', 'carlos-ruiz-zafon', '/authors/OL1392242A', 'Novelista español célebre por la tetralogía de El Cementerio de los Libros Olvidados.', 'https://covers.openlibrary.org/a/olid/OL1392242A-M.jpg', 1964, 'España', 1),
(7, 'Laura Esquivel', 'laura-esquivel', '/authors/OL27268A', 'Escritora mexicana cuya narrativa combina tradición culinaria, intimidad familiar y realismo mágico.', 'https://covers.openlibrary.org/a/olid/OL27268A-M.jpg', 1950, 'México', 1),
(8, 'Roberto Bolaño', 'roberto-bolano', '/authors/OL272541A', 'Narrador y poeta chileno que marcó a toda una generación con novelas sobre la búsqueda literaria y el exilio.', 'https://covers.openlibrary.org/a/olid/OL272541A-M.jpg', 1953, 'Chile', 1),
(9, 'Carlos Fuentes', 'carlos-fuentes', '/authors/OL26342A', 'Uno de los intelectuales y novelistas mexicanos más influyentes del Boom latinoamericano.', 'https://covers.openlibrary.org/a/olid/OL26342A-M.jpg', 1928, 'México', 1),
(10, 'Octavio Paz', 'octavio-paz', '/authors/OL19572A', 'Poeta, ensayista y diplomático mexicano, ganador del Premio Nobel de Literatura en 1990.', 'https://covers.openlibrary.org/a/olid/OL19572A-M.jpg', 1914, 'México', 1),
(11, 'Terry Pratchett', 'terry-pratchett', '/authors/OL25712A', 'Autor británico de fantasía satírica, creador de la saga Mundodisco.', 'https://covers.openlibrary.org/a/olid/OL25712A-M.jpg', 1948, 'Reino Unido', 1),
(12, 'Neil Gaiman', 'neil-gaiman', '/authors/OL23919A', 'Escritor británico de novelas, relatos y cómics de fantasía oscura y mitología moderna.', 'https://covers.openlibrary.org/a/olid/OL23919A-M.jpg', 1960, 'Reino Unido', 1),
(13, 'Elena Garro', 'elena-garro', '/authors/OL283910A', 'Dramaturga, cuentista y novelista mexicana, precursora esencial del realismo mágico en Hispanoamérica.', 'https://covers.openlibrary.org/a/olid/OL283910A-M.jpg', 1916, 'México', 1),
(14, 'Juan Villoro', 'juan-villoro', '/authors/OL281234A', 'Cronista, cuentista y novelista mexicano galardonado con el Premio Herralde y el Premio Xavier Villaurrutia.', 'https://covers.openlibrary.org/a/olid/OL281234A-M.jpg', 1956, 'México', 1),
(15, 'Mario Vargas Llosa', 'mario-vargas-llosa', '/authors/OL24658A', 'Novelista y ensayista peruano, Premio Nobel de Literatura 2010 y figura central del Boom latinoamericano.', 'https://covers.openlibrary.org/a/olid/OL24658A-M.jpg', 1936, 'Perú', 1),
(16, 'Frank Herbert', 'frank-herbert', '/authors/OL79034A', 'Escritor estadounidense de ciencia ficción, célebre por construir uno de los universos ecológicos y políticos más complejos del género.', 'https://covers.openlibrary.org/a/olid/OL79034A-M.jpg', 1920, 'Estados Unidos', 1),
(17, 'Umberto Eco', 'umberto-eco', '/authors/OL24234A', 'Semiólogo, filósofo y novelista italiano que revolucionó la novela histórica con erudición y suspenso detectivesco.', 'https://covers.openlibrary.org/a/olid/OL24234A-M.jpg', 1932, 'Italia', 1);

INSERT INTO `books` (`id`, `title`, `subtitle`, `slug`, `isbn_10`, `isbn_13`, `openlibrary_work_key`, `openlibrary_edition_key`, `publisher`, `published_year`, `page_count`, `language`, `cover_url`, `synopsis`, `price`, `stock`, `status`) VALUES
(1, 'Pedro Páramo', 'Edición crítica anotada', 'pedro-paramo', '8437604184', '9788437604183', '/works/OL1516581W', '/books/OL7418932M', 'Ediciones Cátedra', 2018, 216, 'es', 'https://covers.openlibrary.org/b/isbn/9788437604183-L.jpg?default=false', 'Juan Preciado viaja al pueblo de Comala en busca de su padre, un cacique llamado Pedro Páramo, solo para descubrir que los habitantes del lugar son murmullos y espectros atrapados en la memoria.', 225.00, 18, 'active'),
(2, 'El llano en llamas', 'Edición crítica de Carlos Blanco Aguinaga', 'el-llano-en-llamas', '8437605121', '9788437605128', '/works/OL1516578W', '/books/OL8921341M', 'Ediciones Cátedra', 2017, 240, 'es', 'https://covers.openlibrary.org/b/isbn/9788437605128-L.jpg?default=false', 'Diecisiete relatos magistrales ambientados en el México rural posrevolucionario, donde la sequía, la violencia y la resignación moldean la voz austera de sus protagonistas.', 215.00, 14, 'active'),
(3, 'Cien años de soledad', NULL, 'cien-anos-de-soledad', '8497592204', '9788497592208', '/works/OL27479W', '/books/OL24364628M', 'Debolsillo', 2015, 496, 'es', 'https://covers.openlibrary.org/b/isbn/9788497592208-L.jpg?default=false', 'La saga de siete generaciones de la familia Buendía en el mítico pueblo de Macondo, entre prodigios cotidianos, guerras civiles, amores imposibles y la fatalidad del olvido.', 289.00, 22, 'active'),
(4, 'El amor en los tiempos del cólera', NULL, 'el-amor-en-los-tiempos-del-colera', '849759245X', '9788497592451', '/works/OL27482W', '/books/OL24364645M', 'Debolsillo', 2016, 464, 'es', 'https://covers.openlibrary.org/b/isbn/9788497592451-L.jpg?default=false', 'Florentino Ariza espera más de cincuenta años, nueve meses y cuatro días para volver a declararle su amor a Fermina Daza en una ciudad portuaria del Caribe.', 279.00, 11, 'active'),
(5, 'La casa de los espíritus', NULL, 'la-casa-de-los-espiritus', '8497592255', '9788497592253', '/works/OL66554W', '/books/OL25411902M', 'Debolsillo', 2019, 456, 'es', 'https://covers.openlibrary.org/b/isbn/9788497592253-L.jpg?default=false', 'Cuatro generaciones de la familia Trueba atraviesan el siglo XX chileno entre clarividencias, pasiones desbordadas y convulsiones sociales.', 299.00, 9, 'active'),
(6, 'Ficciones', NULL, 'ficciones', '8420633127', '9788420633121', '/works/OL110971W', '/books/OL9182734M', 'Alianza Editorial', 2014, 218, 'es', 'https://covers.openlibrary.org/b/isbn/9788420633121-L.jpg?default=false', 'Laberintos infinitos, bibliotecas totales, enciclopedias de mundos imaginarios y paradojas del tiempo reunidos en uno de los libros de cuentos más influyentes de la literatura.', 235.00, 16, 'active'),
(7, 'Rayuela', NULL, 'rayuela', '8437604575', '9788437604572', '/works/OL662109W', '/books/OL7419012M', 'Ediciones Cátedra', 2019, 736, 'es', 'https://covers.openlibrary.org/b/isbn/9788437604572-L.jpg?default=false', 'La búsqueda existencial de Horacio Oliveira entre el París bohemio y el Buenos Aires cotidiano, concebida como una novela abierta con múltiples órdenes de lectura.', 329.00, 7, 'active'),
(8, 'La sombra del viento', NULL, 'la-sombra-del-viento', '8408043641', '9788408043645', '/works/OL82563W', '/books/OL26341890M', 'Editorial Planeta', 2016, 576, 'es', 'https://covers.openlibrary.org/b/isbn/9788408043645-L.jpg?default=false', 'En la Barcelona de 1945, el joven Daniel Sempere rescata un libro maldito del Cementerio de los Libros Olvidados y se ve envuelto en una trama de intriga y amor.', 269.00, 20, 'active'),
(9, 'Como agua para chocolate', 'Novela de entregas mensuales con recetas, amores y remedios caseros', 'como-agua-para-chocolate', '8497932501', '9788497932509', '/works/OL472610W', '/books/OL27192834M', 'Debolsillo', 2015, 256, 'es', 'https://covers.openlibrary.org/b/isbn/9788497932509-L.jpg?default=false', 'Tita transforma la cocina de su rancho fronterizo en un espacio de alquimia emocional donde cada platillo transmite sus deseos y melancolías a quienes lo prueban.', 245.00, 12, 'active'),
(10, 'Los detectives salvajes', NULL, 'los-detectives-salvajes', '8433966634', '9788433966636', '/works/OL1818510W', '/books/OL8412930M', 'Editorial Anagrama', 2016, 616, 'es', 'https://covers.openlibrary.org/b/isbn/9788433966636-L.jpg?default=false', 'Arturo Belano y Ulises Lima emprenden en 1975 un viaje desde la Ciudad de México hacia el desierto de Sonora tras el rastro de la poeta desaparecida Cesárea Tinajero.', 349.00, 6, 'active'),
(11, 'Aura', NULL, 'aura', '9684111819', '9789684111813', '/works/OL267332W', '/books/OL9218471M', 'Ediciones Era', 2012, 64, 'es', 'https://covers.openlibrary.org/b/isbn/9789684111813-L.jpg?default=false', 'Un joven historiador acepta redactar las memorias del difunto general Llorente en una casona en penumbras del Centro Histórico, donde conoce a la enigmática Aura.', 165.00, 0, 'out_of_stock'),
(12, 'El laberinto de la soledad', NULL, 'el-laberinto-de-la-soledad', '968161643X', '9789681616434', '/works/OL201894W', '/books/OL9348120M', 'Fondo de Cultura Económica', 2014, 352, 'es', 'https://covers.openlibrary.org/b/isbn/9789681616434-L.jpg?default=false', 'Ensayo fundamental sobre la identidad, los mitos, la historia y las máscaras culturales de México frente al mundo moderno.', 210.00, 15, 'active'),
(13, 'Buenos presagios', 'Las buenas y esmeradas profecías de Agnes Nutter, bruja', 'buenos-presagios', '8445005928', '9788445005927', '/works/OL45804W', '/books/OL28104921M', 'Minotauro', 2019, 416, 'es', 'https://covers.openlibrary.org/b/isbn/9788445005927-L.jpg?default=false', 'Un ángel bibliófilo y un demonio entusiasta de la vida terrestre unen fuerzas para impedir el Apocalipsis porque ambos le han tomado demasiado cariño a la Tierra.', 295.00, 10, 'draft'),
(14, 'Los recuerdos del porvenir', NULL, 'los-recuerdos-del-porvenir', '9682702208', '9789682702204', '/works/OL1518912W', '/books/OL9418273M', 'Editorial Joaquín Mortiz', 2016, 296, 'es', 'https://covers.openlibrary.org/b/isbn/9789682702204-L.jpg?default=false', 'El pueblo de Ixtepec narra en primera persona las pasiones, el miedo y el milagro detenido en el tiempo durante la Guerra Cristera.', 239.00, 13, 'active'),
(15, 'El libro salvaje', NULL, 'el-libro-salvaje', '9681685911', '9789681685911', '/works/OL16184920W', '/books/OL25184920M', 'Fondo de Cultura Económica', 2018, 240, 'es', 'https://covers.openlibrary.org/b/isbn/9789681685911-L.jpg?default=false', 'Durante unas vacaciones en la biblioteca laberíntica de su tío Tito, el joven Juan debe domar un libro rebelde que se niega a ser leído por cualquiera.', 195.00, 25, 'active'),
(16, 'La ciudad y los perros', NULL, 'la-ciudad-y-los-perros', '8420412147', '9788420412146', '/works/OL78542W', '/books/OL24891234M', 'Alfaguara', 2015, 448, 'es', 'https://covers.openlibrary.org/b/isbn/9788420412146-L.jpg?default=false', 'En el Colegio Militar Leoncio Prado de Lima, un grupo de cadetes aprende a sobrevivir bajo un código brutal de lealtades, silencios y violencia institucional.', 285.00, 11, 'active'),
(17, 'Dune', 'Las crónicas de Dune 1', 'dune', '849759682X', '9788497596824', '/works/OL893415W', '/books/OL26891432M', 'Debolsillo', 2019, 784, 'es', 'https://covers.openlibrary.org/b/isbn/9788497596824-L.jpg?default=false', 'En el planeta desértico Arrakis, única fuente de la especia melange, el joven Paul Atreides enfrenta traiciones imperiales y un destino mesiánico.', 359.00, 17, 'active'),
(18, 'El nombre de la rosa', NULL, 'el-nombre-de-la-rosa', '8497592581', '9788497592581', '/works/OL68214W', '/books/OL24901283M', 'Debolsillo', 2016, 672, 'es', 'https://covers.openlibrary.org/b/isbn/9788497592581-L.jpg?default=false', 'En el invierno de 1327, el fraile franciscano Guillermo de Baskerville investiga una serie de muertes misteriosas en una abadía benedictina famosa por su biblioteca secreta.', 319.00, 8, 'active');

INSERT INTO `book_authors` (`book_id`, `author_id`, `author_order`) VALUES
(1, 1, 1),
(2, 1, 1),
(3, 2, 1),
(4, 2, 1),
(5, 3, 1),
(6, 4, 1),
(7, 5, 1),
(8, 6, 1),
(9, 7, 1),
(10, 8, 1),
(11, 9, 1),
(12, 10, 1),
(13, 11, 1),
(13, 12, 2),
(14, 13, 1),
(15, 14, 1),
(16, 15, 1),
(17, 16, 1),
(18, 17, 1);

INSERT INTO `tags` (`id`, `name`, `slug`) VALUES
(1, 'realismo mágico', 'realismo-magico'),
(2, 'narrativa mexicana', 'narrativa-mexicana'),
(3, 'cuento', 'cuento'),
(4, 'clásico contemporáneo', 'clasico-contemporaneo'),
(5, 'misterio', 'misterio'),
(6, 'fantasía', 'fantasia'),
(7, 'ensayo', 'ensayo'),
(8, 'novela histórica', 'novela-historica'),
(9, 'ciencia ficción', 'ciencia-ficcion'),
(10, 'humor', 'humor'),
(11, 'sátira', 'satira'),
(12, 'memoria', 'memoria'),
(13, 'romance', 'romance'),
(14, 'filosofía', 'filosofia'),
(15, 'vanguardia', 'vanguardia'),
(16, 'metaliteratura', 'metaliteratura'),
(17, 'novela negra', 'novela-negra'),
(18, 'literatura juvenil', 'literatura-juvenil'),
(19, 'ecología y política', 'ecologia-y-politica'),
(20, 'clásico universal', 'clasico-universal');

INSERT INTO `book_tags` (`book_id`, `tag_id`) VALUES
(1, 1),
(1, 2),
(1, 4),
(1, 12),
(2, 2),
(2, 3),
(2, 4),
(3, 1),
(3, 4),
(3, 8),
(3, 12),
(4, 1),
(4, 4),
(4, 13),
(5, 1),
(5, 4),
(5, 8),
(5, 12),
(6, 3),
(6, 4),
(6, 6),
(6, 14),
(7, 4),
(7, 14),
(7, 15),
(8, 5),
(8, 8),
(8, 12),
(8, 16),
(9, 1),
(9, 2),
(9, 13),
(10, 2),
(10, 4),
(10, 15),
(10, 16),
(11, 2),
(11, 5),
(11, 6),
(12, 2),
(12, 7),
(12, 12),
(13, 6),
(13, 10),
(13, 11),
(14, 1),
(14, 2),
(14, 8),
(14, 12),
(15, 2),
(15, 6),
(15, 16),
(15, 18),
(16, 4),
(16, 12),
(16, 20),
(17, 9),
(17, 14),
(17, 19),
(17, 20),
(18, 5),
(18, 8),
(18, 14),
(18, 16),
(18, 17);

INSERT INTO `blog_posts` (`id`, `author_id`, `book_id`, `title`, `slug`, `excerpt`, `content`, `rating`, `status`, `published_at`, `created_at`) VALUES
(1, 2, 1, 'Volver a Comala: por qué Pedro Páramo sigue inquietando', 'volver-a-comala-por-que-pedro-paramo-sigue-inquietando-1', 'Una lectura sobre la arquitectura de voces, silencios y remordimientos en la obra maestra de Juan Rulfo.', 'Leer Pedro Páramo por primera vez es entrar en una conversación cuyos interlocutores cambian sin previo aviso. Juan Rulfo elimina cualquier explicación innecesaria y confía en que el lector arme el rompecabezas de Comala a partir de susurros, recuerdos de lluvia y rencores heredados.\n\nA diferencia de la novela decimonónica que guía al lector de la mano, aquí el paisaje ardiente de Jalisco funciona como una caja de resonancia emocional. Cada fragmento ilumina desde otro ángulo la figura despótica de Pedro Páramo, cuyo poder económico contrasta con su absoluta impotencia frente al amor inalcanzable de Susana San Juan.\n\nEsta edición crítica de Cátedra resulta especialmente valiosa porque contextualiza las variantes textuales y la depuración poética a la que Rulfo sometió su manuscrito. Es un libro breve en páginas pero inmenso en resonancia: cada relectura descubre un vínculo nuevo entre los habitantes del pueblo.', 5, 'published', '2026-10-22 10:00:00', '2026-10-22 09:15:00'),
(2, 2, 1, 'Guía de relectura: el tiempo fragmentado en Pedro Páramo', 'guia-de-relectura-el-tiempo-fragmentado-en-pedro-paramo-2', 'Notas prácticas para seguir los saltos temporales y las voces narrativas en una segunda lectura.', 'Cuando regresamos a Pedro Páramo sabiendo quién habla desde cada sepultura, la novela revela una precisión relojera. Lo que en la primera lectura parece caos onírico es en realidad una estructura cuidadosamente montada alrededor de tres ejes: el viaje de Juan Preciado, el ascenso caciquil de Pedro y el monólogo interior de Susana San Juan.\n\nUn recurso útil durante la relectura consiste en prestar atención a los cambios de clima y a las transiciones entre diálogos en primera persona y narración omnisciente. Rulfo utiliza el murmullo del agua y el viento nocturno como bisagras temporales que conectan décadas distintas sin necesidad de fechar los capítulos.\n\nSi buscas una edición para subrayar y discutir en club de lectura, esta versión anotada ofrece claves imprescindibles sin arruinar el misterio poético de la obra.', 5, 'published', '2026-11-04 16:30:00', '2026-11-04 15:40:00'),
(3, 1, 3, 'Macondo como espejo de la memoria latinoamericana', 'macondo-como-espejo-de-la-memoria-latinoamericana-3', 'De la fundación junto al río de piedras diáfanas al pergamino final de Melquíades.', 'Pocas primeras líneas en la historia de la novela tienen el magnetismo de Cien años de soledad. Gabriel García Márquez convierte lo extraordinario en rutina doméstica: los galeones encallados en la selva, la peste del insomnio o las mariposas amarillas se narran con la misma naturalidad que una receta familiar en la cocina de Úrsula Iguarán.\n\nMás allá del deslumbramiento verbal, la novela es una meditación profunda sobre la soledad como destino histórico y la necesidad de contar historias para no desaparecer en el olvido. Cada generación de los Buendía repite nombres y obsesiones mientras Macondo transita de aldea utópica a enclave bananero marcado por la violencia.\n\nEsta edición de bolsillo mantiene una tipografía cómoda e incluye el árbol genealógico al inicio, un aliado indispensable para no perderse entre tantos Aurelianos y José Arcadios.', 5, 'published', '2026-10-25 12:00:00', '2026-10-25 11:00:00'),
(4, 4, 6, 'Mapas para perderse: el universo exacto de Ficciones', 'mapas-para-perderse-el-universo-exacto-de-ficciones-4', 'Por qué los cuentos de Jorge Luis Borges funcionan como máquinas filosóficas perfectas.', 'En Ficciones cada cuento parece contener una biblioteca entera comprimida en diez páginas. Desde Tlön, Uqbar, Orbis Tertius hasta La biblioteca de Babel y El jardín de senderos que se bifurcan, Borges convierte problemas metafísicos en relatos de suspenso intelectual donde la erudición es motor dramático.\n\nLa prosa borgiana destaca por su economía adjetival y su ironía sutil: bajo la apariencia de reseñas bibliográficas o notas necrológicas, los textos plantean preguntas vertiginosas sobre la identidad, el azar y los límites del lenguaje humano para ordenar el caos del universo.\n\nNo hace falta ser especialista en filosofía para disfrutarlo: basta la curiosidad por los espejos, los libros imaginarios y las bifurcaciones del destino.', 5, 'published', '2026-10-28 18:00:00', '2026-10-28 17:10:00'),
(5, 2, 8, 'Un homenaje inolvidable al oficio de librero', 'un-homenaje-inolvidable-al-oficio-de-librero-5', 'La sombra del viento combina folletín gótico, misterio y amor por los libros.', 'Pocos escenarios resultan tan seductores para cualquier lector como el Cementerio de los Libros Olvidados en el corazón de la Barcelona de posguerra. Cuando el joven Daniel Sempere elige un ejemplar solitario de Julián Carax, inicia una investigación que entreteje secretos familiares, pasiones truncadas y persecuciones políticas.\n\nCarlos Ruiz Zafón construye una novela adictiva donde cada personaje secundario —en especial el inolvidable Fermín Romero de Torres— aporta humor, humanidad y brillo dialogado frente a las sombras de la ciudad gótica.\n\nEs una recomendación infalible para quienes buscan una lectura envolvente de principio a fin, con ritmo cinematográfico y reverencia genuina por la palabra impresa.', 4, 'published', '2026-11-01 11:20:00', '2026-11-01 10:30:00'),
(6, 4, 9, 'Sabores que cuentan una vida entera', 'sabores-que-cuentan-una-vida-entera-6', 'El recetario emocional de Laura Esquivel sigue conquistando nuevas generaciones de lectores.', 'Organizada como un calendario gastronómico mensual, Como agua para chocolate demuestra que la intimidad de una cocina puede sostener una historia épica sobre el deseo y la libertad personal. Obligada por una tradición familiar injusta a permanecer soltera, Tita encuentra en los fogones el único lenguaje capaz de expresar lo que le prohíben decir.\n\nLa novela integra ingredientes reales y pasos culinarios con episodios de desbordamiento fantástico donde las lágrimas salan un pastel de bodas y los pétalos de rosa despiertan pasiones irreprimibles.\n\nLa combinación entre humor, tradición mexicana y realismo mágico hace que sea un libro cálido y memorable de principio a fin.', 4, 'published', '2026-11-03 14:15:00', '2026-11-03 13:20:00'),
(7, 1, 10, 'La épica coral de la poesía joven en Los detectives salvajes', 'la-epica-coral-de-la-poesia-joven-en-los-detectives-salvajes-7', 'Decenas de testimonios reconstruyen el rastro del realismo visceral por medio mundo.', 'Roberto Bolaño logra una proeza narrativa: contar la historia de dos poetas casi sin mostrarlos directamente en el tramo central, dejando que sean sus amigos, amantes, editores y detractores quienes dibujen su retrato a lo largo de veinte años de errancia entre Ciudad de México, París, Barcelona, Tel Aviv y el desierto de Sonora.\n\nEl diario inicial de Juan García Madero captura con frescura y humor la efervescencia juvenil de los cafés literarios de los años setenta, antes de abrir paso a una polifonía vertiginosa donde cada voz tiene cadencia propia.\n\nUn libro torrencial, divertido y melancólico sobre la juventud, la amistad y el precio de mantener viva la vocación literaria.', 5, 'published', '2026-11-06 19:00:00', '2026-11-06 18:05:00'),
(8, 4, 5, 'Memoria familiar y resistencia en La casa de los espíritus', 'memoria-familiar-y-resistencia-en-la-casa-de-los-espiritus-8', 'Clara, Blanca y Alba: tres generaciones de mujeres que sostienen la historia frente al autoritarismo.', 'Isabel Allende debutó con una novela monumental donde lo íntimo y lo histórico avanzan inseparables. A través del contraste entre el carácter patriarcal de Esteban Trueba y la sensibilidad clarividente de Clara del Valle, la trama retrata las transformaciones sociales de Chile durante el siglo XX.\n\nLos cuadernos de anotar la vida de Clara se convierten en el hilo narrativo que permite a su nieta Alba reconstruir la memoria familiar incluso en medio del terror político y la censura.\n\nUna lectura esencial dentro de la narrativa hispanoamericana moderna por su fuerza emocional y su vigor narrativo.', 5, 'published', '2026-11-08 13:45:00', '2026-11-08 12:50:00'),
(9, 2, 7, 'Cómo entrar en Rayuela sin miedo al tablero de dirección', 'como-entrar-en-rayuela-sin-miedo-al-tablero-de-direccion-9', 'Lectura lineal o lectura saltada: dos caminos igualmente válidos para explorar la novela de Cortázar.', 'Rayuela sigue siendo una invitación a jugar con las reglas de la novela tradicional. Ya sea siguiendo los capítulos del 1 al 56 o aceptando el itinerario propuesto por Julio Cortázar —que incorpora los capítulos prescindibles llenos de notas de Morelli, recortes y reflexiones estéticas—, el libro mantiene una frescura inimitable.\n\nLa relación entre Horacio Oliveira y la Maga, las reuniones del Club de la Serpiente en París y el inolvidable episodio del puente de tablones en Buenos Aires pertenecen ya a la memoria colectiva de los lectores en español.\n\nConviene acercarse a ella sin solemnidad académica: dejarse llevar por el ritmo jazzístico de su prosa es la mejor brújula posible.', 4, 'published', '2026-11-10 17:10:00', '2026-11-10 16:00:00'),
(10, 1, 12, 'Releer El laberinto de la soledad hoy', 'releer-el-laberinto-de-la-soledad-hoy-10', 'Un clásico del ensayo mexicano para dialogar críticamente con nuestra historia.', 'Más que un conjunto de respuestas cerradas, El laberinto de la soledad es una invitación a examinar nuestros símbolos, fiestas y silencios cotidianos con rigor literario. Escrito originalmente a mediados del siglo XX, el libro mantiene una capacidad sorprendente para provocar debate.\n\nOctavio Paz enlaza historia prehispánica, herencia colonial, Revolución Mexicana y modernidad mediante una prosa ensayística luminosa que avanza por imágenes poéticas y contrastes filosóficos.\n\nEsta edición del Fondo de Cultura Económica incluye además Postdata y Vuelta a El laberinto de la soledad, permitiendo apreciar la evolución del pensamiento del autor.', 4, 'published', '2026-11-13 11:00:00', '2026-11-13 10:10:00'),
(11, 4, 13, 'Apocalipsis con humor británico: adelanto de Buenos presagios', 'apocalipsis-con-humor-britanico-adelanto-de-buenos-presagios-11', 'Borrador de reseña para el próximo ingreso al catálogo de fantasía humorística.', 'Cuando Terry Pratchett y Neil Gaiman unieron sus plumas, el resultado fue una comedia apocalíptica repleta de ironía sobre la burocracia celestial e infernal. Azirafel, un ángel librero con debilidad por los restaurantes antiguos, y Crowley, un demonio que conduce un Bentley clásico, deciden sabotear el fin del mundo tras once años cuidando al Anticristo equivocado.\n\nLa novela brilla por sus notas al pie mordaces, sus jinetes del Apocalipsis motorizados y una mirada sorprendentemente tierna hacia las imperfecciones humanas.\n\nPendiente de publicar en cuanto recibamos el lote en almacén.', 5, 'draft', NULL, '2026-11-15 15:20:00'),
(12, 2, 14, 'Ixtepec habla: la poesía trágica de Los recuerdos del porvenir', 'ixtepec-habla-la-poesia-tragica-de-los-recuerdos-del-porvenir-12', 'Elena Garro convierte a un pueblo entero en narrador colectivo de la memoria y el desengaño.', 'Desde sus primeras páginas, Los recuerdos del porvenir deslumbra con una decisión narrativa audaz: quien habla no es un personaje individual, sino el propio pueblo de Ixtepec contemplando su historia desde una piedra en la loma. A través de esa voz coral desfilan la ocupación militar durante la Guerra Cristera, la llegada de la enigmática Julia Andrade y la resistencia de los hermanos Moncada.\n\nPublicada en 1963, la novela anticipa muchos de los hallazgos del realismo mágico con una prosa lírica donde el tiempo puede detenerse literalmente ante la intensidad del amor o la tragedia.\n\nEs una lectura indispensable para comprender la literatura mexicana del siglo XX en toda su riqueza.', 5, 'published', '2026-11-14 09:30:00', '2026-11-14 08:45:00'),
(13, 4, 15, 'El libro salvaje: una aventura para lectores de todas las edades', 'el-libro-salvaje-una-aventura-para-lectores-de-todas-las-edades-13', 'Juan Villoro transforma una biblioteca doméstica en territorio de exploración y humor.', 'Pocas novelas transmiten con tanta alegría el placer físico y mental de perderse entre estanterías como El libro salvaje. Cuando Juan debe pasar el verano en la casa de su excéntrico tío Tito —un bibliófilo rodeado de montañas de volúmenes que cambian de lugar por sí solos—, descubre que los libros eligen a sus lectores y no al revés.\n\nCon agilidad narrativa y guiños inteligentes a los clásicos, Juan Villoro construye una historia sobre la empatía, la curiosidad y el poder de las palabras para ordenar las emociones difíciles de la adolescencia.\n\nIdeal tanto para lectores jóvenes como para adultos que conservan el asombro por las bibliotecas.', 5, 'published', '2026-11-15 12:10:00', '2026-11-15 11:20:00'),
(14, 1, 17, 'Ecología, política y mito en Dune de Frank Herbert', 'ecologia-politica-y-mito-en-dune-de-frank-herbert-14', 'Por qué la epopeya de Arrakis sigue siendo el referente mayor de la ciencia ficción moderna.', 'Más de medio siglo después de su publicación original, Dune conserva una vigencia asombrosa gracias a la profundidad con la que Frank Herbert diseñó el ecosistema del planeta Arrakis. Aquí el desierto no es un simple telón de fondo, sino un organismo vivo donde cada gota de agua define la cultura, la religión y la estrategia militar de los fremen.\n\nLa caída de la Casa Atreides y el ascenso de Paul Muad Dib se narran con la densidad de una crónica histórica, explorando los peligros del mesianismo político y la dependencia de recursos estratégicos como la especia melange.\n\nEsta edición de bolsillo incluye los apéndices ecológicos y el glosario del Imperio, fundamentales para sumergirse de lleno en la saga.', 5, 'published', '2026-11-16 14:00:00', '2026-11-16 13:10:00'),
(15, 4, 18, 'Crímenes en la abadía: el laberinto erudito de El nombre de la rosa', 'crimenes-en-la-abadia-el-laberinto-erudito-de-el-nombre-de-la-rosa-15', 'Umberto Eco entrelaza novela policiaca medieval, filosofía y amor por los manuscritos.', 'Ambientada durante siete días cruciales en noviembre de 1327, El nombre de la rosa convierte una abadía benedictina del norte de Italia en el escenario de una investigación fascinante. Guillermo de Baskerville, un franciscano de mirada deductiva que recuerda inevitablemente a Sherlock Holmes, y su joven novicio Adso de Melk deben descifrar una cadena de muertes ligadas a un libro prohibido.\n\nUmberto Eco logra equilibrar el suspenso detectivesco con diálogos brillantes sobre la risa, la herejía, la semiótica y la preservación del conocimiento antiguo dentro del laberinto de la biblioteca.\n\nUna novela monumental que recompensa tanto al lector de intriga histórica como al apasionado por los libros dentro de los libros.', 5, 'published', '2026-11-17 10:30:00', '2026-11-17 09:40:00');

INSERT INTO `blog_post_tags` (`post_id`, `tag_id`) VALUES
(1, 1),
(1, 2),
(1, 4),
(1, 12),
(2, 2),
(2, 4),
(2, 16),
(3, 1),
(3, 4),
(3, 8),
(3, 12),
(4, 3),
(4, 4),
(4, 6),
(4, 14),
(5, 5),
(5, 8),
(5, 16),
(6, 1),
(6, 2),
(6, 13),
(7, 2),
(7, 4),
(7, 15),
(7, 16),
(8, 1),
(8, 8),
(8, 12),
(9, 4),
(9, 14),
(9, 15),
(10, 2),
(10, 7),
(10, 12),
(11, 6),
(11, 10),
(11, 11),
(12, 1),
(12, 2),
(12, 8),
(12, 12),
(13, 2),
(13, 6),
(13, 16),
(13, 18),
(14, 9),
(14, 14),
(14, 19),
(14, 20),
(15, 5),
(15, 8),
(15, 14),
(15, 16),
(15, 17);

INSERT INTO `blog_votes` (`id`, `user_id`, `post_id`, `vote_value`, `created_at`) VALUES
(1, 3, 1, 1, '2026-10-22 14:11:00'),
(2, 5, 1, 1, '2026-10-23 09:36:00'),
(3, 6, 1, 1, '2026-10-24 11:20:00'),
(4, 7, 1, 1, '2026-10-25 15:00:00'),
(5, 6, 2, 1, '2026-11-05 18:21:00'),
(6, 3, 2, 1, '2026-11-06 10:12:00'),
(7, 5, 3, 1, '2026-10-26 11:06:00'),
(8, 7, 3, 1, '2026-10-27 16:41:00'),
(9, 3, 3, 1, '2026-10-28 09:00:00'),
(10, 3, 4, 1, '2026-10-29 20:16:00'),
(11, 6, 4, 1, '2026-10-30 08:51:00'),
(12, 3, 5, 1, '2026-11-02 13:26:00'),
(13, 7, 5, 1, '2026-11-02 19:11:00'),
(14, 5, 5, -1, '2026-11-03 14:00:00'),
(15, 5, 6, 1, '2026-11-04 10:46:00'),
(16, 3, 7, 1, '2026-11-07 21:31:00'),
(17, 2, 7, 1, '2026-11-08 09:16:00'),
(18, 6, 8, 1, '2026-11-09 15:01:00'),
(19, 5, 9, 1, '2026-11-11 12:31:00'),
(20, 3, 10, 1, '2026-11-14 17:46:00'),
(21, 5, 12, 1, '2026-11-14 13:10:00'),
(22, 9, 12, 1, '2026-11-14 18:20:00'),
(23, 7, 13, 1, '2026-11-15 16:05:00'),
(24, 10, 13, 1, '2026-11-15 20:30:00'),
(25, 3, 14, 1, '2026-11-16 15:40:00'),
(26, 10, 14, 1, '2026-11-16 18:12:00'),
(27, 9, 14, 1, '2026-11-16 21:05:00'),
(28, 9, 15, 1, '2026-11-17 11:45:00'),
(29, 3, 15, 1, '2026-11-17 13:20:00'),
(30, 6, 15, 1, '2026-11-17 15:00:00');

INSERT INTO `comments` (`id`, `post_id`, `user_id`, `content`, `status`, `moderated_by`, `moderated_at`, `created_at`) VALUES
(1, 1, 3, 'Excelente reseña. Justo compré esta edición anotada y las notas al pie ayudan muchísimo en la primera lectura.', 'visible', NULL, NULL, '2026-10-22 14:10:00'),
(2, 1, 5, 'Comala es uno de los escenarios más inolvidables de toda la literatura en español.', 'visible', NULL, NULL, '2026-10-23 09:35:00'),
(3, 2, 6, 'Esta guía de relectura me dio ganas de volver a abrir el libro este fin de semana.', 'visible', NULL, NULL, '2026-11-05 18:20:00'),
(4, 3, 5, 'La escena del hielo al inicio sigue poniéndome la piel de gallina cada vez que la leo.', 'visible', NULL, NULL, '2026-10-26 11:05:00'),
(5, 3, 7, 'Lo pedí ayer en la tienda aprovechando la reseña, ¡qué ganas de que llegue!', 'visible', NULL, NULL, '2026-10-27 16:40:00'),
(6, 4, 3, 'La biblioteca de Babel es mi cuento favorito de todo el volumen. Pura precisión.', 'visible', NULL, NULL, '2026-10-29 20:15:00'),
(7, 4, 6, 'Borges logra en diez páginas lo que otros autores no consiguen en cuatrocientas.', 'visible', NULL, NULL, '2026-10-30 08:50:00'),
(8, 5, 3, 'Me atrapó desde el primer capítulo. El ambiente de la Barcelona antigua es increíble.', 'visible', NULL, NULL, '2026-11-02 13:25:00'),
(9, 5, 7, 'Totalmente de acuerdo, Fermín Romero de Torres es un personaje entrañable.', 'visible', NULL, NULL, '2026-11-02 19:10:00'),
(10, 6, 5, 'Siempre termino con antojo de chocolate caliente y torrejas después de leerlo.', 'visible', NULL, NULL, '2026-11-04 10:45:00'),
(11, 7, 3, 'Gran análisis, Fernando. La segunda parte con los testimonios cruzados es una maravilla narrativa.', 'visible', NULL, NULL, '2026-11-07 21:30:00'),
(12, 7, 2, 'Coincido con ustedes: el tramo final en el desierto de Sonora tiene una fuerza única.', 'visible', NULL, NULL, '2026-11-08 09:15:00'),
(13, 8, 6, 'La casa de los espíritus fue el libro que me inició en la lectura hace años.', 'visible', NULL, NULL, '2026-11-09 15:00:00'),
(14, 9, 5, 'Yo lo leí siguiendo el tablero de dirección y fue una experiencia divertidísima.', 'visible', NULL, NULL, '2026-11-11 12:30:00'),
(15, 10, 3, 'Indispensable para entender el ensayo mexicano del siglo XX.', 'visible', NULL, NULL, '2026-11-14 17:45:00'),
(16, 5, 6, 'Comentario eliminado por duplicidad durante prueba.', 'hidden', 1, '2026-11-03 08:00:00', '2026-11-03 08:00:00'),
(17, 12, 5, 'El recurso de que el propio pueblo de Ixtepec sea quien narra me pareció fascinante desde la primera página.', 'visible', NULL, NULL, '2026-11-14 13:15:00'),
(18, 12, 9, 'Qué bueno ver reseñada a Elena Garro con este nivel de detalle. Directo a mi carrito.', 'visible', NULL, NULL, '2026-11-14 18:25:00'),
(19, 13, 10, 'Se lo regalé a mi sobrino el mes pasado y terminamos leyéndolo los dos al mismo tiempo.', 'visible', NULL, NULL, '2026-11-15 20:35:00'),
(20, 14, 3, 'Los apéndices ecológicos al final de Dune son oro puro para entender Arrakis.', 'visible', NULL, NULL, '2026-11-16 15:45:00'),
(21, 14, 10, 'Una obra maestra absoluta de la ciencia ficción. La construcción política entre casas es impecable.', 'visible', NULL, NULL, '2026-11-16 18:15:00'),
(22, 15, 9, 'Guillermo de Baskerville y Adso forman una de las mejores duplas detectivescas de la literatura.', 'visible', NULL, NULL, '2026-11-17 11:50:00'),
(23, 15, 6, 'El plano de la abadía al inicio del libro ayuda muchísimo a seguir las pistas.', 'visible', NULL, NULL, '2026-11-17 15:05:00'),
(24, 15, 4, 'Gracias por comentar, Diego y Lucía. Esa edición de Debolsillo conserva el mapa original de la biblioteca.', 'visible', NULL, NULL, '2026-11-17 16:10:00');

INSERT INTO `comment_media` (`id`, `comment_id`, `provider`, `media_type`, `giphy_id`, `media_url`, `preview_url`, `width`, `height`, `alt_text`, `created_at`) VALUES
(1, 1, 'giphy', 'gif', '7MDZS8zS1ixtJAUEul', 'https://media1.giphy.com/media/7MDZS8zS1ixtJAUEul/200.gif', 'https://media1.giphy.com/media/7MDZS8zS1ixtJAUEul/200_s.gif', 356, 200, 'Come On Wow GIF by BrownSugarApp', '2026-10-22 14:10:00'),
(2, 5, 'giphy', 'gif', '3o7abKhOpu0NwenH3O', 'https://media2.giphy.com/media/3o7abKhOpu0NwenH3O/200.gif', 'https://media2.giphy.com/media/3o7abKhOpu0NwenH3O/200_s.gif', 320, 200, 'Excited Reading Book GIF', '2026-10-27 16:40:00'),
(3, 8, 'giphy', 'gif', 'WoWm8YzFQJg5i', 'https://media0.giphy.com/media/WoWm8YzFQJg5i/200.gif', 'https://media0.giphy.com/media/WoWm8YzFQJg5i/200_s.gif', 266, 200, 'SpongeBob Reading Fast GIF', '2026-11-02 13:25:00'),
(4, 14, 'giphy', 'sticker', 'l0MYt5jPR6QX5pnqM', 'https://media3.giphy.com/media/l0MYt5jPR6QX5pnqM/200.gif', 'https://media3.giphy.com/media/l0MYt5jPR6QX5pnqM/200_s.gif', 200, 200, 'Celebration Sticker', '2026-11-11 12:30:00'),
(5, 20, 'giphy', 'gif', 'UJG2T7uZeJuZCLitY8', 'https://media1.giphy.com/media/UJG2T7uZeJuZCLitY8/200.gif', 'https://media1.giphy.com/media/UJG2T7uZeJuZCLitY8/200_s.gif', 356, 200, 'Desert Sand Dunes Sci-Fi GIF', '2026-11-16 15:45:00'),
(6, 22, 'giphy', 'gif', 'SiGg4zSmwmbafTYwpj', 'https://media2.giphy.com/media/SiGg4zSmwmbafTYwpj/200.gif', 'https://media2.giphy.com/media/SiGg4zSmwmbafTYwpj/200_s.gif', 300, 200, 'Detective Magnifying Glass GIF', '2026-11-17 11:50:00');

INSERT INTO `private_messages` (`id`, `sender_id`, `recipient_id`, `content`, `sent_at`, `read_at`, `sender_deleted_at`, `recipient_deleted_at`) VALUES
(1, 3, 2, 'Hola Alejandra, leí tu reseña de Pedro Páramo y me gustaría saber si recomiendas empezar por ese o por El llano en llamas.', '2026-10-23 10:00:00', '2026-10-23 10:25:00', NULL, NULL),
(2, 2, 3, '¡Hola Pedro! Si quieres entrar poco a poco al estilo de Rulfo, El llano en llamas es una puerta magnífica; después Pedro Páramo se disfruta aún más.', '2026-10-23 10:30:00', '2026-10-23 11:00:00', NULL, NULL),
(3, 3, 2, 'Muchas gracias por el consejo, agregaré ambos a mi carrito.', '2026-10-23 11:05:00', '2026-10-23 11:15:00', NULL, NULL),
(4, 7, 1, 'Buenas tardes Fernando, ¿saben cuándo volverá a haber existencia de Aura de Carlos Fuentes en la tienda?', '2026-11-10 12:15:00', '2026-11-10 13:00:00', NULL, NULL),
(5, 1, 7, 'Hola Valeria, recibimos reabastecimiento de Ediciones Era la próxima semana. Te aviso en cuanto actualicemos el inventario.', '2026-11-10 13:10:00', '2026-11-10 14:00:00', NULL, NULL),
(6, 4, 1, 'Fernando, ya subí el borrador de la reseña de Buenos presagios para cuando demos de alta el lote en stock.', '2026-11-15 15:25:00', '2026-11-15 16:00:00', NULL, NULL),
(7, 1, 4, 'Perfecto Mariana, reviso la ficha hoy por la tarde y activamos el libro en catálogo.', '2026-11-15 16:12:00', NULL, NULL, NULL),
(8, 5, 6, 'Hola Diego, vi tu comentario en Ficciones. ¿Ya leíste El Aleph?', '2026-11-12 19:00:00', '2026-11-12 20:10:00', NULL, NULL),
(9, 6, 5, 'Aún no, Sofía, lo tengo en mi lista de pendientes para este mes.', '2026-11-12 20:20:00', NULL, NULL, NULL),
(10, 9, 4, 'Hola Mariana, gracias por recomendar El nombre de la rosa. ¿Tienen pensado reseñar El péndulo de Foucault próximamente?', '2026-11-17 16:30:00', '2026-11-17 17:00:00', NULL, NULL),
(11, 4, 9, '¡Hola Lucía! Sí, lo tenemos en agenda para diciembre junto con otras novelas históricas.', '2026-11-17 17:15:00', NULL, NULL, NULL),
(12, 10, 3, 'Qué tal Pedro, vi que también te gusta la ciencia ficción. ¿Ya leíste El mesías de Dune?', '2026-11-17 18:05:00', NULL, NULL, NULL);

INSERT INTO `shopping_carts` (`id`, `user_id`, `status`, `created_at`, `updated_at`) VALUES
(1, 3, 'checked_out', '2026-10-24 15:00:00', '2026-10-24 15:20:00'),
(2, 7, 'checked_out', '2026-10-27 16:00:00', '2026-10-27 16:30:00'),
(3, 5, 'checked_out', '2026-11-05 11:00:00', '2026-11-05 11:25:00'),
(4, 6, 'checked_out', '2026-11-12 18:00:00', '2026-11-12 18:15:00'),
(5, 6, 'abandoned', '2026-11-01 21:00:00', '2026-11-04 21:00:00'),
(6, 3, 'active', '2026-11-15 19:10:00', '2026-11-16 09:40:00'),
(7, 5, 'active', '2026-11-16 10:05:00', '2026-11-16 10:15:00'),
(8, 9, 'checked_out', '2026-11-14 19:00:00', '2026-11-14 19:20:00'),
(9, 10, 'checked_out', '2026-11-16 19:00:00', '2026-11-16 19:15:00'),
(10, 10, 'active', '2026-11-17 14:10:00', '2026-11-17 14:25:00');

INSERT INTO `cart_items` (`id`, `cart_id`, `book_id`, `quantity`, `created_at`) VALUES
(1, 1, 1, 1, '2026-10-24 15:02:00'),
(2, 1, 2, 1, '2026-10-24 15:05:00'),
(3, 2, 3, 1, '2026-10-27 16:05:00'),
(4, 2, 8, 1, '2026-10-27 16:10:00'),
(5, 3, 6, 1, '2026-11-05 11:05:00'),
(6, 3, 9, 2, '2026-11-05 11:12:00'),
(7, 4, 10, 1, '2026-11-12 18:05:00'),
(8, 5, 7, 1, '2026-11-01 21:05:00'),
(9, 6, 6, 1, '2026-11-15 19:12:00'),
(10, 6, 12, 1, '2026-11-16 09:40:00'),
(11, 7, 5, 1, '2026-11-16 10:15:00'),
(12, 8, 14, 1, '2026-11-14 19:05:00'),
(13, 8, 18, 1, '2026-11-14 19:10:00'),
(14, 9, 17, 1, '2026-11-16 19:05:00'),
(15, 10, 15, 2, '2026-11-17 14:25:00');

INSERT INTO `orders` (`id`, `order_reference`, `user_id`, `cart_id`, `status`, `subtotal`, `shipping_cost`, `total_amount`, `currency`, `shipping_recipient_name`, `shipping_phone`, `shipping_address_line`, `shipping_city`, `shipping_state`, `shipping_postal_code`, `shipping_country`, `shipping_notes`, `tracking_number`, `shipped_at`, `delivered_at`, `status_updated_by`, `created_at`) VALUES
(1, 'EL-2026-00001', 3, 1, 'delivered', 440.00, 79.00, 519.00, 'MXN', 'Pedro Hernández', '5548921104', 'Calle Colima 192, Depto. 302, Col. Roma Norte', 'Ciudad de México', 'Ciudad de México', '06700', 'México', 'Entregar en recepción de edificio, torre B.', 'ESTAFETA-8941203941', '2026-10-25 11:00:00', '2026-10-27 15:40:00', 1, '2026-10-24 15:20:00'),
(2, 'EL-2026-00002', 7, 2, 'shipped', 558.00, 0.00, 558.00, 'MXN', 'Valeria Ortiz', '4427812390', 'Blvd. Bernardo Quintana 4050, Col. Álamos 3a Sección', 'Santiago de Querétaro', 'Querétaro', '76160', 'México', 'Casa con portón negro frente al parque.', 'DHL-MX-492018472', '2026-10-29 10:15:00', NULL, 1, '2026-10-27 16:30:00'),
(3, 'EL-2026-00003', 5, 3, 'preparing', 725.00, 0.00, 725.00, 'MXN', 'Sofía Mendoza', '8124509912', 'Calzada del Valle 315, Col. Del Valle', 'San Pedro Garza García', 'Nuevo León', '66220', 'México', NULL, NULL, NULL, NULL, 1, '2026-11-05 11:25:00'),
(4, 'EL-2026-00004', 6, 4, 'pending_payment', 349.00, 79.00, 428.00, 'MXN', 'Diego Ramírez', '2226190438', 'Av. Juárez 1508, Col. La Paz', 'Puebla', 'Puebla', '72160', 'México', 'Llamar 10 minutos antes de llegar.', NULL, NULL, NULL, NULL, '2026-11-12 18:15:00'),
(5, 'EL-2026-00005', 9, 8, 'delivered', 558.00, 0.00, 558.00, 'MXN', 'Lucía Castellanos', '4428193340', 'Av. Zaragoza 112, Col. Niños Héroes', 'Santiago de Querétaro', 'Querétaro', '76010', 'México', 'Dejar con vigilancia si no hay nadie en casa.', 'DHL-MX-518293041', '2026-11-15 09:30:00', '2026-11-16 14:20:00', 1, '2026-11-14 19:20:00'),
(6, 'EL-2026-00006', 10, 9, 'paid', 359.00, 79.00, 438.00, 'MXN', 'Mateo Morales', '5539104482', 'Av. División del Norte 1420, Col. Letrán Valle', 'Ciudad de México', 'Ciudad de México', '03650', 'México', NULL, NULL, NULL, NULL, NULL, '2026-11-16 19:15:00');

INSERT INTO `order_items` (`id`, `order_id`, `book_id`, `book_title_snapshot`, `book_isbn_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES
(1, 1, 1, 'Pedro Páramo', '9788437604183', 225.00, 1, 225.00),
(2, 1, 2, 'El llano en llamas', '9788437605128', 215.00, 1, 215.00),
(3, 2, 3, 'Cien años de soledad', '9788497592208', 289.00, 1, 289.00),
(4, 2, 8, 'La sombra del viento', '9788408043645', 269.00, 1, 269.00),
(5, 3, 6, 'Ficciones', '9788420633121', 235.00, 1, 235.00),
(6, 3, 9, 'Como agua para chocolate', '9788497932509', 245.00, 2, 490.00),
(7, 4, 10, 'Los detectives salvajes', '9788433966636', 349.00, 1, 349.00),
(8, 5, 14, 'Los recuerdos del porvenir', '9789682702204', 239.00, 1, 239.00),
(9, 5, 18, 'El nombre de la rosa', '9788497592581', 319.00, 1, 319.00),
(10, 6, 17, 'Dune', '9788497596824', 359.00, 1, 359.00);

INSERT INTO `payments` (`id`, `order_id`, `provider`, `paypal_order_id`, `paypal_capture_id`, `payer_email`, `payer_paypal_id`, `amount`, `currency`, `status`, `raw_response_summary`, `paid_at`, `created_at`) VALUES
(1, 1, 'paypal', '5O190127TN364715T', '2GG279541U471931P', 'pedro.sandbox@personal.example.com', 'PAYPALUSR003MX', 519.00, 'MXN', 'completed', 'COMPLETED - PayPal Checkout Sandbox Capture', '2026-10-24 15:21:12', '2026-10-24 15:20:00'),
(2, 2, 'paypal', '8A739104KL928371M', '9HJ827163R501928K', 'valeria.sandbox@personal.example.com', 'PAYPALUSR007MX', 558.00, 'MXN', 'completed', 'COMPLETED - PayPal Checkout Sandbox Capture', '2026-10-27 16:31:05', '2026-10-27 16:30:00'),
(3, 3, 'paypal', '3C492018QW746291Z', '6TY918273B402918V', 'sofia.sandbox@personal.example.com', 'PAYPALUSR005MX', 725.00, 'MXN', 'completed', 'COMPLETED - PayPal Checkout Sandbox Capture', '2026-11-05 11:26:40', '2026-11-05 11:25:00'),
(4, 4, 'paypal', '9P182736MN546372X', NULL, 'diego.sandbox@personal.example.com', 'PAYPALUSR006MX', 428.00, 'MXN', 'created', 'CREATED - Awaiting buyer approval in PayPal', NULL, '2026-11-12 18:15:00'),
(5, 5, 'paypal', '4K829104RT618293L', '7MN918273C510928J', 'lucia.sandbox@personal.example.com', 'PAYPALUSR009MX', 558.00, 'MXN', 'completed', 'COMPLETED - PayPal Checkout Sandbox Capture', '2026-11-14 19:21:10', '2026-11-14 19:20:00'),
(6, 6, 'paypal', '2W918273PL402918Q', '1ZX827163V619283H', 'mateo.sandbox@personal.example.com', 'PAYPALUSR010MX', 438.00, 'MXN', 'completed', 'COMPLETED - PayPal Checkout Sandbox Capture', '2026-11-16 19:16:02', '2026-11-16 19:15:00');

INSERT INTO `invoices` (`id`, `order_id`, `payment_id`, `invoice_number`, `customer_name`, `customer_email`, `billing_address`, `subtotal`, `shipping_cost`, `total_amount`, `currency`, `pdf_storage_path`, `issued_at`) VALUES
(1, 1, 1, 'FAC-2026-00001', 'Pedro Hernández', 'pedro@gmail.com', 'Calle Colima 192, Depto. 302, Col. Roma Norte, Ciudad de México, Ciudad de México, C.P. 06700, México', 440.00, 79.00, 519.00, 'MXN', 'storage/invoices/2026/10/FAC-2026-00001.pdf', '2026-10-24 15:21:15'),
(2, 2, 2, 'FAC-2026-00002', 'Valeria Ortiz', 'valeria.ortiz@correo.mx', 'Blvd. Bernardo Quintana 4050, Col. Álamos 3a Sección, Santiago de Querétaro, Querétaro, C.P. 76160, México', 558.00, 0.00, 558.00, 'MXN', 'storage/invoices/2026/10/FAC-2026-00002.pdf', '2026-10-27 16:31:08'),
(3, 3, 3, 'FAC-2026-00003', 'Sofía Mendoza', 'sofia.mendoza@correo.mx', 'Calzada del Valle 315, Col. Del Valle, San Pedro Garza García, Nuevo León, C.P. 66220, México', 725.00, 0.00, 725.00, 'MXN', 'storage/invoices/2026/11/FAC-2026-00003.pdf', '2026-11-05 11:26:44'),
(4, 5, 5, 'FAC-2026-00004', 'Lucía Castellanos', 'lucia.castellanos@correo.mx', 'Av. Zaragoza 112, Col. Niños Héroes, Santiago de Querétaro, Querétaro, C.P. 76010, México', 558.00, 0.00, 558.00, 'MXN', 'storage/invoices/2026/11/FAC-2026-00004.pdf', '2026-11-14 19:21:14'),
(5, 6, 6, 'FAC-2026-00005', 'Mateo Morales', 'mateo.morales@correo.mx', 'Av. División del Norte 1420, Col. Letrán Valle, Ciudad de México, Ciudad de México, C.P. 03650, México', 359.00, 79.00, 438.00, 'MXN', 'storage/invoices/2026/11/FAC-2026-00005.pdf', '2026-11-16 19:16:05');

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET TIME_ZONE=@OLD_TIME_ZONE;