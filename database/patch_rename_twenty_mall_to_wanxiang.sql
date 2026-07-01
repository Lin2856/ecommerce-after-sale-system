USE ecommerce_after_sale;
SET NAMES utf8mb4;

SET @old_platform_name := CONVERT(CONCAT('20', '商城') USING utf8mb4) COLLATE utf8mb4_unicode_ci;
SET @new_platform_name := CONVERT('万象商城' USING utf8mb4) COLLATE utf8mb4_unicode_ci;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'external_platform'),
  'UPDATE external_platform SET platform_name = REPLACE(platform_name, @old_platform_name, @new_platform_name) WHERE platform_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sync_task'),
  'UPDATE sync_task SET task_name = REPLACE(task_name, @old_platform_name, @new_platform_name) WHERE task_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'platform_account_binding'),
  'UPDATE platform_account_binding SET platform_name = REPLACE(platform_name, @old_platform_name, @new_platform_name) WHERE platform_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'twenty_mall_account'),
  'UPDATE twenty_mall_account SET display_name = REPLACE(display_name, @old_platform_name, @new_platform_name) WHERE display_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'twenty_mall_product'),
  'UPDATE twenty_mall_product SET product_name = REPLACE(product_name, @old_platform_name, @new_platform_name), description = REPLACE(description, @old_platform_name, @new_platform_name) WHERE product_name LIKE CONCAT(''%'', @old_platform_name, ''%'') OR description LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'twenty_mall_order_item'),
  'UPDATE twenty_mall_order_item SET product_name = REPLACE(product_name, @old_platform_name, @new_platform_name) WHERE product_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  EXISTS (SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'external_order_item'),
  'UPDATE external_order_item SET product_name = REPLACE(product_name, @old_platform_name, @new_platform_name) WHERE product_name LIKE CONCAT(''%'', @old_platform_name, ''%'')',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
