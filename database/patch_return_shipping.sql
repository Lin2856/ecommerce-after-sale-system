USE ecommerce_after_sale;

SET NAMES utf8mb4;

SET @has_return_tracking_no := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_after_sale'
    AND COLUMN_NAME = 'return_tracking_no'
);

SET @add_return_tracking_no_sql := IF(
  @has_return_tracking_no = 0,
  'ALTER TABLE twenty_mall_after_sale ADD COLUMN return_tracking_no VARCHAR(64) NULL AFTER status',
  'SELECT 1'
);
PREPARE add_return_tracking_no_stmt FROM @add_return_tracking_no_sql;
EXECUTE add_return_tracking_no_stmt;
DEALLOCATE PREPARE add_return_tracking_no_stmt;

SET @has_return_shipped_at := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_after_sale'
    AND COLUMN_NAME = 'return_shipped_at'
);

SET @add_return_shipped_at_sql := IF(
  @has_return_shipped_at = 0,
  'ALTER TABLE twenty_mall_after_sale ADD COLUMN return_shipped_at DATETIME NULL AFTER return_tracking_no',
  'SELECT 1'
);
PREPARE add_return_shipped_at_stmt FROM @add_return_shipped_at_sql;
EXECUTE add_return_shipped_at_stmt;
DEALLOCATE PREPARE add_return_shipped_at_stmt;
