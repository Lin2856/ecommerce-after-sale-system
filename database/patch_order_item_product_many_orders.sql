SET @index_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'twenty_mall_order_item'
    AND INDEX_NAME = 'idx_twenty_mall_order_item_product'
);

SET @sql := IF(
  @index_exists = 0,
  'ALTER TABLE twenty_mall_order_item ADD INDEX idx_twenty_mall_order_item_product (product_id)',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
