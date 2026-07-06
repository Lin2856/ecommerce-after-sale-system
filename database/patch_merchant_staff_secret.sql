USE ecommerce_after_sale;
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS merchant_staff_secret (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  primary_account VARCHAR(64) NOT NULL COMMENT '商家端一级账号',
  staff_code VARCHAR(16) NOT NULL COMMENT '客服编号',
  staff_name VARCHAR(64) NOT NULL COMMENT '客服名称',
  secret_key VARCHAR(32) NOT NULL COMMENT '客服身份确认秘钥',
  status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uk_merchant_staff_secret (primary_account, staff_code, deleted),
  KEY idx_merchant_staff_secret_account (primary_account),
  KEY idx_merchant_staff_secret_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商家端客服身份秘钥';

INSERT INTO merchant_staff_secret (primary_account, staff_code, staff_name, secret_key, status, deleted)
SELECT pa.account_no, seed.staff_code, seed.staff_name, seed.secret_key, 'ACTIVE', 0
FROM primary_account pa
JOIN (
  SELECT 'A' AS staff_code, '客服A' AS staff_name, 'k7Pq4Lm2' AS secret_key
  UNION ALL SELECT 'B', '客服B', 'V3nT8zQ6'
  UNION ALL SELECT 'C', '客服C', 'b9Xr2Hc5'
  UNION ALL SELECT 'D', '客服D', 'M6sY1wFp'
) seed
WHERE pa.account_type = 'MERCHANT'
  AND pa.status = 'ACTIVE'
  AND pa.deleted = 0
ON DUPLICATE KEY UPDATE
  staff_name = VALUES(staff_name),
  secret_key = VALUES(secret_key),
  status = 'ACTIVE',
  deleted = 0,
  updated_at = NOW();
