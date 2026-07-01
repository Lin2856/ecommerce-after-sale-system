CREATE TABLE IF NOT EXISTS twenty_mall_after_sale_dispute (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  after_sale_id BIGINT NOT NULL,
  order_no VARCHAR(64) NOT NULL,
  consumer_reason TEXT NOT NULL,
  consumer_evidence_json JSON NULL,
  merchant_evidence_text TEXT NULL,
  merchant_evidence_json JSON NULL,
  admin_result VARCHAR(32) NULL,
  admin_note TEXT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted TINYINT(1) NOT NULL DEFAULT 0,
  KEY idx_twenty_dispute_after_sale (after_sale_id),
  KEY idx_twenty_dispute_order (order_no),
  KEY idx_twenty_dispute_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='万象商城售后争议订单';
