USE ecommerce_after_sale;
SET NAMES utf8mb4;

SET @has_platform_code := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_account'
    AND COLUMN_NAME = 'platform_code'
);
SET @add_platform_code_sql := IF(
  @has_platform_code = 0,
  'ALTER TABLE twenty_mall_account ADD COLUMN platform_code VARCHAR(32) NOT NULL DEFAULT ''TWENTY_MALL'' AFTER id',
  'SELECT 1'
);
PREPARE add_platform_code_stmt FROM @add_platform_code_sql;
EXECUTE add_platform_code_stmt;
DEALLOCATE PREPARE add_platform_code_stmt;

UPDATE twenty_mall_account
SET platform_code = 'TWENTY_MALL'
WHERE platform_code IS NULL OR platform_code = '';

SET @has_old_unique := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_account'
    AND INDEX_NAME = 'uk_twenty_mall_account_no_role'
);
SET @drop_old_unique_sql := IF(
  @has_old_unique = 1,
  'ALTER TABLE twenty_mall_account DROP INDEX uk_twenty_mall_account_no_role',
  'SELECT 1'
);
PREPARE drop_old_unique_stmt FROM @drop_old_unique_sql;
EXECUTE drop_old_unique_stmt;
DEALLOCATE PREPARE drop_old_unique_stmt;

SET @has_new_unique := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_account'
    AND INDEX_NAME = 'uk_twenty_mall_account_platform_no_role'
);
SET @add_new_unique_sql := IF(
  @has_new_unique = 0,
  'ALTER TABLE twenty_mall_account ADD UNIQUE KEY uk_twenty_mall_account_platform_no_role (platform_code, account_no, account_role)',
  'SELECT 1'
);
PREPARE add_new_unique_stmt FROM @add_new_unique_sql;
EXECUTE add_new_unique_stmt;
DEALLOCATE PREPARE add_new_unique_stmt;

UPDATE platform_account_binding
SET bind_status = 'UNBOUND', unbound_at = NOW(), updated_at = NOW()
WHERE platform_code = 'YUEGOU_MARKET'
  AND secondary_account_no IN ('20230141', '20230142', '20230143', '22222223', '22222224')
  AND deleted = 0;

INSERT INTO twenty_mall_account (
  platform_code, account_no, password_plain, account_role, display_name, phone, bind_status, status, deleted
) VALUES
  ('YUEGOU_MARKET', '30330001', '123456', 'CONSUMER', '悦购集市消费者一号', '13330003001', 'UNBOUND', 'ACTIVE', 0),
  ('YUEGOU_MARKET', '30330142', '123456', 'MERCHANT', '悦购箱包优选店', '16630003042', 'UNBOUND', 'ACTIVE', 0),
  ('YUEGOU_MARKET', '30330143', '123456', 'MERCHANT', '悦购生活百货店', '16630003043', 'UNBOUND', 'ACTIVE', 0)
ON DUPLICATE KEY UPDATE
  password_plain = VALUES(password_plain),
  display_name = VALUES(display_name),
  phone = VALUES(phone),
  status = 'ACTIVE',
  deleted = 0,
  updated_at = NOW();
