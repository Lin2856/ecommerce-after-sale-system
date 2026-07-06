USE ecommerce_after_sale;
SET NAMES utf8mb4;

INSERT INTO primary_account (account_no, account_type, display_name, login_mode, status, deleted)
VALUES ('13338907682', 'MERCHANT', '商家空白一级账号', 'DEMO_CODE', 'ACTIVE', 0)
ON DUPLICATE KEY UPDATE
  login_mode = VALUES(login_mode),
  status = 'ACTIVE',
  deleted = 0,
  updated_at = NOW();

INSERT INTO platform_account_binding (
  primary_account_id,
  platform_code,
  platform_name,
  secondary_account_no,
  secondary_account_role,
  bind_status,
  bound_at,
  unbound_at,
  deleted
)
SELECT
  pa.id,
  'YUEGOU_MARKET',
  '悦购集市',
  account.account_no,
  'MERCHANT',
  'BOUND',
  NOW(),
  NULL,
  0
FROM primary_account pa
JOIN twenty_mall_account account
  ON account.platform_code = 'YUEGOU_MARKET'
  AND account.account_role = 'MERCHANT'
  AND account.deleted = 0
WHERE pa.account_no = '13338907682'
  AND pa.account_type = 'MERCHANT'
  AND pa.deleted = 0
ON DUPLICATE KEY UPDATE
  primary_account_id = VALUES(primary_account_id),
  platform_name = VALUES(platform_name),
  bind_status = 'BOUND',
  bound_at = VALUES(bound_at),
  unbound_at = NULL,
  deleted = 0,
  updated_at = NOW();

UPDATE twenty_mall_account
SET bind_status = 'BOUND',
    updated_at = NOW()
WHERE platform_code = 'YUEGOU_MARKET'
  AND account_role = 'MERCHANT'
  AND deleted = 0;
