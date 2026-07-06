USE ecommerce_after_sale;

SET @add_secret_key_sql = (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE admin_account ADD COLUMN secret_key VARCHAR(32) NOT NULL DEFAULT '''' COMMENT ''管理员登录秘钥'' AFTER admin_name',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admin_account'
    AND COLUMN_NAME = 'secret_key'
);
PREPARE stmt FROM @add_secret_key_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE admin_account
SET secret_key = CASE admin_code
  WHEN 'admin-a' THEN 'A7mP4qR2'
  WHEN 'admin-b' THEN 'z9KxT3vB'
  WHEN 'admin-c' THEN 'Q6nL8sWa'
  WHEN 'admin-d' THEN 'b2Hc7YdM'
  ELSE secret_key
END,
updated_at = NOW()
WHERE admin_code IN ('admin-a', 'admin-b', 'admin-c', 'admin-d');

SET @drop_secret_salt_sql = (
  SELECT IF(
    COUNT(*) > 0,
    'ALTER TABLE admin_account DROP COLUMN secret_salt',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admin_account'
    AND COLUMN_NAME = 'secret_salt'
);
PREPARE stmt FROM @drop_secret_salt_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @drop_secret_hash_sql = (
  SELECT IF(
    COUNT(*) > 0,
    'ALTER TABLE admin_account DROP COLUMN secret_hash',
    'SELECT 1'
  )
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'admin_account'
    AND COLUMN_NAME = 'secret_hash'
);
PREPARE stmt FROM @drop_secret_hash_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
