USE ecommerce_after_sale;
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS primary_account (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  account_no VARCHAR(64) NOT NULL,
  account_type VARCHAR(32) NOT NULL,
  display_name VARCHAR(128) NOT NULL,
  password_plain VARCHAR(128) NULL,
  login_mode VARCHAR(32) NOT NULL DEFAULT 'DEMO',
  status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uk_primary_account_no_type (account_no, account_type),
  KEY idx_primary_account_type (account_type),
  KEY idx_primary_account_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @has_primary_phone := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'primary_account'
    AND COLUMN_NAME = 'phone'
);
SET @add_primary_phone_sql := IF(
  @has_primary_phone = 0,
  'ALTER TABLE primary_account ADD COLUMN phone VARCHAR(32) NULL AFTER display_name',
  'SELECT 1'
);
PREPARE add_primary_phone_stmt FROM @add_primary_phone_sql;
EXECUTE add_primary_phone_stmt;
DEALLOCATE PREPARE add_primary_phone_stmt;

SET @has_primary_password := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'primary_account'
    AND COLUMN_NAME = 'password_plain'
);
SET @add_primary_password_sql := IF(
  @has_primary_password = 0,
  'ALTER TABLE primary_account ADD COLUMN password_plain VARCHAR(128) NULL AFTER phone',
  'SELECT 1'
);
PREPARE add_primary_password_stmt FROM @add_primary_password_sql;
EXECUTE add_primary_password_stmt;
DEALLOCATE PREPARE add_primary_password_stmt;

SET @has_primary_avatar := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'primary_account'
    AND COLUMN_NAME = 'avatar_url'
);
SET @add_primary_avatar_sql := IF(
  @has_primary_avatar = 0,
  'ALTER TABLE primary_account ADD COLUMN avatar_url VARCHAR(512) NULL AFTER phone',
  'SELECT 1'
);
PREPARE add_primary_avatar_stmt FROM @add_primary_avatar_sql;
EXECUTE add_primary_avatar_stmt;
DEALLOCATE PREPARE add_primary_avatar_stmt;

ALTER TABLE primary_account
  MODIFY COLUMN avatar_url LONGTEXT NULL;

CREATE TABLE IF NOT EXISTS platform_account_binding (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  primary_account_id BIGINT NOT NULL,
  platform_code VARCHAR(32) NOT NULL,
  platform_name VARCHAR(64) NOT NULL,
  secondary_account_no VARCHAR(64) NOT NULL,
  secondary_account_role VARCHAR(32) NOT NULL,
  bind_status VARCHAR(32) NOT NULL DEFAULT 'BOUND',
  bound_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  unbound_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uk_platform_secondary_active (platform_code, secondary_account_no, secondary_account_role, deleted),
  KEY idx_platform_binding_primary (primary_account_id),
  KEY idx_platform_binding_status (bind_status),
  CONSTRAINT fk_platform_binding_primary_account
    FOREIGN KEY (primary_account_id) REFERENCES primary_account(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO primary_account (account_no, account_type, display_name, password_plain, login_mode, status)
VALUES
  ('13338907583', 'CONSUMER', '愤怒的耄耋', 'n4Tg8Pq2', 'PASSWORD', 'ACTIVE'),
  ('13338907582', 'CONSUMER', '消费者空白一级账号', 'Q7mZ2aK9', 'PASSWORD', 'ACTIVE'),
  ('13338907681', 'MERCHANT', '商家演示一级账号', 'R6xB9vL3', 'PASSWORD', 'ACTIVE'),
  ('13338907682', 'MERCHANT', '商家空白一级账号', 'h8Kp5Yw1', 'PASSWORD', 'ACTIVE')
ON DUPLICATE KEY UPDATE
  display_name = VALUES(display_name),
  password_plain = VALUES(password_plain),
  login_mode = VALUES(login_mode),
  status = VALUES(status),
  deleted = 0,
  updated_at = NOW();

UPDATE primary_account
SET phone = account_no
WHERE phone IS NULL OR phone = '';

UPDATE primary_account
SET password_plain = '123456'
WHERE deleted = 0
  AND (password_plain IS NULL OR password_plain = '');

UPDATE primary_account
SET deleted = 1,
    status = 'DELETED',
    updated_at = NOW()
WHERE (account_no = '13338907581' AND account_type = 'CONSUMER')
   OR (account_no = '13338907582' AND account_type = 'MERCHANT');

INSERT INTO platform_account_binding (
  primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
)
SELECT pa.id, 'TWENTY_MALL', '万象商城', '20230140', 'CONSUMER', 'BOUND', NOW(), 0
FROM primary_account pa
WHERE pa.account_no = '13338907583' AND pa.account_type = 'CONSUMER'
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();

INSERT INTO platform_account_binding (
  primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
)
SELECT pa.id, 'TWENTY_MALL', '万象商城', '20230141', 'CONSUMER', 'BOUND', NOW(), 0
FROM primary_account pa
WHERE pa.account_no = '13338907583' AND pa.account_type = 'CONSUMER'
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();

INSERT INTO platform_account_binding (
  primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
)
SELECT pa.id, 'TWENTY_MALL', '万象商城', '22222222', 'CONSUMER', 'BOUND', NOW(), 0
FROM primary_account pa
WHERE pa.account_no = '13338907582' AND pa.account_type = 'CONSUMER'
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();

INSERT INTO platform_account_binding (
  primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
)
SELECT pa.id, 'TWENTY_MALL', '万象商城', tm.account_no, 'MERCHANT', 'BOUND', NOW(), 0
FROM primary_account pa
JOIN twenty_mall_account tm ON tm.account_no IN ('20230141', '20230142')
  AND tm.account_role = 'MERCHANT'
  AND tm.deleted = 0
WHERE pa.account_no = '13338907681' AND pa.account_type = 'MERCHANT'
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();

INSERT INTO platform_account_binding (
  primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
)
SELECT pa.id, 'TWENTY_MALL', '万象商城', tm.account_no, 'MERCHANT', 'BOUND', NOW(), 0
FROM primary_account pa
JOIN twenty_mall_account tm ON tm.account_no IN ('22222223', '22222224')
  AND tm.account_role = 'MERCHANT'
  AND tm.deleted = 0
WHERE pa.account_no = '13338907682' AND pa.account_type = 'MERCHANT'
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();
