USE ecommerce_after_sale;

CREATE TABLE IF NOT EXISTS merchant_operation_log (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  primary_account VARCHAR(64) NOT NULL COMMENT '商家端一级账号',
  staff_code VARCHAR(16) NOT NULL COMMENT '客服编号',
  staff_name VARCHAR(64) NOT NULL COMMENT '客服名称',
  action_type VARCHAR(64) NOT NULL COMMENT '操作类型',
  action_name VARCHAR(128) NOT NULL COMMENT '操作名称',
  target_type VARCHAR(64) NOT NULL COMMENT '操作对象类型',
  target_id VARCHAR(128) NULL COMMENT '操作对象编号',
  detail VARCHAR(500) NULL COMMENT '操作内容',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  INDEX idx_merchant_operation_primary_account (primary_account),
  INDEX idx_merchant_operation_staff (staff_code),
  INDEX idx_merchant_operation_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商家端客服操作日志';
