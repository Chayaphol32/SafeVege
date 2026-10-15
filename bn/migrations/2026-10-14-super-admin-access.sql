ALTER TABLE users
  MODIFY use_role ENUM('shop','admin','super_admin') NOT NULL;

CREATE TABLE IF NOT EXISTS app_settings (
  set_key VARCHAR(100) NOT NULL,
  set_value JSON NOT NULL,
  set_updated_by BIGINT UNSIGNED NOT NULL,
  set_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (set_key),
  CONSTRAINT fk_app_settings_user FOREIGN KEY (set_updated_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW api_app_settings AS SELECT
  set_key AS setting_key,
  set_value AS setting_value,
  set_updated_by AS setting_updated_by,
  set_updated_at AS setting_updated_at
FROM app_settings;
