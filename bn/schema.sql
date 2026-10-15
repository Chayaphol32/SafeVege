-- SafeVege database schema (MySQL 5.7+, InnoDB, utf8mb4)
-- Run on a new server/database only. Review before applying to existing data.
CREATE DATABASE IF NOT EXISTS safevege CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE safevege;

CREATE TABLE IF NOT EXISTS users (
  use_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  use_username VARCHAR(100) NOT NULL,
  use_password VARCHAR(255) NOT NULL,
  use_display_name VARCHAR(150) NOT NULL,
  use_role ENUM('shop','admin','super_admin') NOT NULL,
  use_is_active TINYINT(1) NOT NULL DEFAULT 1,
  use_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  use_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (use_id),
  UNIQUE KEY uq_users_username (use_username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS api_tokens (
  tok_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tok_user_id BIGINT UNSIGNED NOT NULL,
  tok_hash CHAR(64) NOT NULL,
  tok_expires_at DATETIME NOT NULL,
  tok_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (tok_id),
  UNIQUE KEY uq_api_tokens_hash (tok_hash),
  KEY idx_api_tokens_user (tok_user_id),
  KEY idx_api_tokens_expiry (tok_expires_at),
  CONSTRAINT fk_api_tokens_user FOREIGN KEY (tok_user_id) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS shops (
  shop_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  shop_owner_user_id BIGINT UNSIGNED NOT NULL,
  shop_name VARCHAR(255) NOT NULL,
  shop_owner_first_name VARCHAR(100) NOT NULL,
  shop_owner_last_name VARCHAR(100) NOT NULL,
  shop_phone VARCHAR(30) NOT NULL,
  shop_house_number VARCHAR(100) DEFAULT NULL,
  shop_moo VARCHAR(30) DEFAULT NULL,
  shop_street VARCHAR(150) DEFAULT NULL,
  shop_subdistrict VARCHAR(150) DEFAULT NULL,
  shop_district VARCHAR(150) DEFAULT NULL,
  shop_province VARCHAR(150) DEFAULT NULL,
  shop_postal_code VARCHAR(10) DEFAULT NULL,
  shop_latitude DECIMAL(10,7) DEFAULT NULL,
  shop_longitude DECIMAL(10,7) DEFAULT NULL,
  shop_is_public TINYINT(1) NOT NULL DEFAULT 0,
  shop_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  shop_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (shop_id),
  KEY idx_shops_owner (shop_owner_user_id),
  KEY idx_shops_public_location (shop_is_public, shop_latitude, shop_longitude),
  KEY idx_shops_name (shop_name),
  CONSTRAINT fk_shops_owner FOREIGN KEY (shop_owner_user_id) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspection_requests (
  req_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  req_shop_id BIGINT UNSIGNED NOT NULL,
  req_no VARCHAR(32) NOT NULL,
  req_status ENUM('submitted','scheduled','inspected','published','cancelled') NOT NULL DEFAULT 'submitted',
  req_address_snapshot VARCHAR(500) NOT NULL,
  req_latitude_snapshot DECIMAL(10,7) DEFAULT NULL,
  req_longitude_snapshot DECIMAL(10,7) DEFAULT NULL,
  req_submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  req_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (req_id),
  UNIQUE KEY uq_requests_no (req_no),
  KEY idx_requests_shop_date (req_shop_id, req_submitted_at),
  KEY idx_requests_status_date (req_status, req_submitted_at),
  CONSTRAINT fk_requests_shop FOREIGN KEY (req_shop_id) REFERENCES shops(shop_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspection_request_items (
  item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  item_request_id BIGINT UNSIGNED NOT NULL,
  item_vegetable_name VARCHAR(255) NOT NULL,
  item_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (item_id),
  KEY idx_request_items_request (item_request_id),
  CONSTRAINT fk_request_items_request FOREIGN KEY (item_request_id) REFERENCES inspection_requests(req_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspection_appointments (
  apt_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  apt_request_id BIGINT UNSIGNED NOT NULL,
  apt_appointment_at DATETIME NOT NULL,
  apt_note VARCHAR(500) DEFAULT NULL,
  apt_scheduled_by BIGINT UNSIGNED NOT NULL,
  apt_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (apt_id),
  KEY idx_appointments_request_date (apt_request_id, apt_created_at),
  KEY idx_appointments_date (apt_appointment_at),
  CONSTRAINT fk_appointments_request FOREIGN KEY (apt_request_id) REFERENCES inspection_requests(req_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_appointments_admin FOREIGN KEY (apt_scheduled_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inspection_results (
  res_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  res_request_item_id BIGINT UNSIGNED NOT NULL,
  res_revision_no INT UNSIGNED NOT NULL DEFAULT 1,
  res_outcome ENUM('passed','failed','inconclusive') NOT NULL,
  res_inspected_at DATETIME NOT NULL,
  res_recorded_by BIGINT UNSIGNED NOT NULL,
  res_note TEXT,
  res_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (res_id),
  UNIQUE KEY uq_results_item_revision (res_request_item_id, res_revision_no),
  KEY idx_results_inspected_at (res_inspected_at),
  CONSTRAINT fk_results_item FOREIGN KEY (res_request_item_id) REFERENCES inspection_request_items(item_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_results_admin FOREIGN KEY (res_recorded_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS certificates (
  cert_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  cert_request_id BIGINT UNSIGNED NOT NULL,
  cert_no VARCHAR(64) NOT NULL,
  cert_file_path VARCHAR(500) NOT NULL,
  cert_mime_type ENUM('application/pdf','image/jpeg') NOT NULL,
  cert_issued_at DATE NOT NULL,
  cert_expires_at DATE DEFAULT NULL,
  cert_is_public TINYINT(1) NOT NULL DEFAULT 0,
  cert_uploaded_by BIGINT UNSIGNED NOT NULL,
  cert_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (cert_id),
  UNIQUE KEY uq_certificates_no (cert_no),
  KEY idx_certificates_request (cert_request_id),
  KEY idx_certificates_public_expiry (cert_is_public, cert_expires_at),
  CONSTRAINT fk_certificates_request FOREIGN KEY (cert_request_id) REFERENCES inspection_requests(req_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_certificates_admin FOREIGN KEY (cert_uploaded_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS certificate_results (
  cr_certificate_id BIGINT UNSIGNED NOT NULL,
  cr_result_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (cr_certificate_id, cr_result_id),
  KEY idx_certificate_results_result (cr_result_id),
  CONSTRAINT fk_certificate_results_certificate FOREIGN KEY (cr_certificate_id) REFERENCES certificates(cert_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_certificate_results_result FOREIGN KEY (cr_result_id) REFERENCES inspection_results(res_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_events (
  aud_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  aud_actor_user_id BIGINT UNSIGNED NOT NULL,
  aud_entity_type VARCHAR(50) NOT NULL,
  aud_entity_id BIGINT UNSIGNED NOT NULL,
  aud_action VARCHAR(50) NOT NULL,
  aud_details JSON,
  aud_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (aud_id),
  KEY idx_audit_entity_date (aud_entity_type, aud_entity_id, aud_created_at),
  KEY idx_audit_actor_date (aud_actor_user_id, aud_created_at),
  CONSTRAINT fk_audit_actor FOREIGN KEY (aud_actor_user_id) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_settings (
  set_key VARCHAR(100) NOT NULL,
  set_value JSON NOT NULL,
  set_updated_by BIGINT UNSIGNED NOT NULL,
  set_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (set_key),
  CONSTRAINT fk_app_settings_user FOREIGN KEY (set_updated_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Internal API compatibility views keep the JSON contract stable.
CREATE OR REPLACE VIEW api_users AS SELECT
  use_id AS id,
  use_username AS username,
  use_password AS password_hash,
  use_display_name AS display_name,
  use_role AS role,
  use_is_active AS is_active,
  use_created_at AS created_at,
  use_updated_at AS updated_at
FROM users;

CREATE OR REPLACE VIEW api_api_tokens AS SELECT
  tok_id AS id,
  tok_user_id AS user_id,
  tok_hash AS token_hash,
  tok_expires_at AS expires_at,
  tok_created_at AS created_at
FROM api_tokens;

CREATE OR REPLACE VIEW api_shops AS SELECT
  shop_id AS id,
  shop_owner_user_id AS owner_user_id,
  shop_name AS name,
  shop_owner_first_name AS owner_first_name,
  shop_owner_last_name AS owner_last_name,
  shop_phone AS phone,
  shop_house_number AS house_number,
  shop_moo AS moo,
  shop_street AS street,
  shop_subdistrict AS subdistrict,
  shop_district AS district,
  shop_province AS province,
  shop_postal_code AS postal_code,
  shop_latitude AS latitude,
  shop_longitude AS longitude,
  shop_is_public AS is_public,
  shop_created_at AS created_at,
  shop_updated_at AS updated_at
FROM shops;

CREATE OR REPLACE VIEW api_inspection_requests AS SELECT
  req_id AS id,
  req_shop_id AS shop_id,
  req_no AS request_no,
  req_status AS status,
  req_address_snapshot AS address_snapshot,
  req_latitude_snapshot AS latitude_snapshot,
  req_longitude_snapshot AS longitude_snapshot,
  req_submitted_at AS submitted_at,
  req_updated_at AS updated_at
FROM inspection_requests;

CREATE OR REPLACE VIEW api_inspection_request_items AS SELECT
  item_id AS id,
  item_request_id AS request_id,
  item_vegetable_name AS vegetable_name,
  item_created_at AS created_at
FROM inspection_request_items;

CREATE OR REPLACE VIEW api_inspection_appointments AS SELECT
  apt_id AS id,
  apt_request_id AS request_id,
  apt_appointment_at AS appointment_at,
  apt_note AS note,
  apt_scheduled_by AS scheduled_by,
  apt_created_at AS created_at
FROM inspection_appointments;

CREATE OR REPLACE VIEW api_inspection_results AS SELECT
  res_id AS id,
  res_request_item_id AS request_item_id,
  res_revision_no AS revision_no,
  res_outcome AS outcome,
  res_inspected_at AS inspected_at,
  res_recorded_by AS recorded_by,
  res_note AS note,
  res_created_at AS created_at
FROM inspection_results;

CREATE OR REPLACE VIEW api_certificates AS SELECT
  cert_id AS id,
  cert_request_id AS request_id,
  cert_no AS certificate_no,
  cert_file_path AS file_path,
  cert_mime_type AS mime_type,
  cert_issued_at AS issued_at,
  cert_expires_at AS expires_at,
  cert_is_public AS is_public,
  cert_uploaded_by AS uploaded_by,
  cert_created_at AS created_at
FROM certificates;

CREATE OR REPLACE VIEW api_certificate_results AS SELECT
  cr_certificate_id AS certificate_id,
  cr_result_id AS result_id
FROM certificate_results;

CREATE OR REPLACE VIEW api_audit_events AS SELECT
  aud_id AS id,
  aud_actor_user_id AS actor_user_id,
  aud_entity_type AS entity_type,
  aud_entity_id AS entity_id,
  aud_action AS action,
  aud_details AS details,
  aud_created_at AS created_at
FROM audit_events;

CREATE OR REPLACE VIEW api_app_settings AS SELECT
  set_key AS setting_key,
  set_value AS setting_value,
  set_updated_by AS setting_updated_by,
  set_updated_at AS setting_updated_at
FROM app_settings;
