-- Create Wanxiang Mall merchant account 20230143 and consumer account 33333333,
-- then seed 10 food-store orders with no after-sale request and no review.

SET NAMES utf8mb4;

INSERT INTO twenty_mall_account (account_no, password_plain, account_role, display_name, bind_status, status, deleted)
VALUES
  ('20230143', '123456', 'MERCHANT', '美味食品专卖店', 'UNBOUND', 'ACTIVE', 0),
  ('33333333', '123456', 'CONSUMER', '薄荷汽水铺', 'UNBOUND', 'ACTIVE', 0)
ON DUPLICATE KEY UPDATE
  password_plain = VALUES(password_plain),
  account_role = VALUES(account_role),
  display_name = VALUES(display_name),
  status = 'ACTIVE',
  deleted = 0,
  updated_at = NOW();

SET @merchant_id = (
  SELECT id FROM twenty_mall_account
  WHERE account_no = '20230143' AND account_role = 'MERCHANT' AND deleted = 0
  LIMIT 1
);
SET @consumer_id = (
  SELECT id FROM twenty_mall_account
  WHERE account_no = '33333333' AND account_role = 'CONSUMER' AND deleted = 0
  LIMIT 1
);

INSERT INTO twenty_mall_product (
  merchant_account_id, product_no, product_name, product_image_url, price, stock, category, description, status, deleted
)
VALUES
  (@merchant_id, 'WX-FOOD-20230143-001', '万象商城 手工牛轧糖', '/assets/products/twenty-cup.png', 39.90, 300, '休闲零食', '奶香浓郁的手工牛轧糖，适合办公室零食和节日分享。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-002', '万象商城 蜂蜜柚子茶', '/assets/products/twenty-cup.png', 49.90, 240, '冲调饮品', '精选柚皮与蜂蜜调制，冷热冲饮皆可。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-003', '万象商城 原味坚果礼盒', '/assets/products/twenty-cup.png', 128.00, 180, '坚果礼盒', '多种坚果组合装，独立小袋包装。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-004', '万象商城 低糖燕麦饼干', '/assets/products/twenty-cup.png', 29.90, 360, '饼干糕点', '低糖配方燕麦饼干，口感酥脆。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-005', '万象商城 冻干草莓脆', '/assets/products/twenty-cup.png', 36.80, 220, '果干蜜饯', '整颗草莓冻干，保留水果香气。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-006', '万象商城 黑芝麻丸', '/assets/products/twenty-cup.png', 45.00, 260, '营养食品', '黑芝麻与蜂蜜制成，独立包装便于携带。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-007', '万象商城 桂花酸梅汤', '/assets/products/twenty-cup.png', 26.90, 280, '冲调饮品', '桂花风味酸梅汤浓缩饮品，酸甜清爽。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-008', '万象商城 海盐苏打饼干', '/assets/products/twenty-cup.png', 19.90, 420, '饼干糕点', '海盐口味苏打饼干，轻咸酥脆。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-009', '万象商城 即食鸡胸肉', '/assets/products/twenty-cup.png', 59.90, 160, '即食食品', '低脂即食鸡胸肉，多口味组合。', 'ON_SALE', 0),
  (@merchant_id, 'WX-FOOD-20230143-010', '万象商城 有机小米', '/assets/products/twenty-cup.png', 32.50, 200, '粮油米面', '产地直采有机小米，适合煮粥。', 'ON_SALE', 0)
ON DUPLICATE KEY UPDATE
  merchant_account_id = VALUES(merchant_account_id),
  product_name = VALUES(product_name),
  product_image_url = VALUES(product_image_url),
  price = VALUES(price),
  stock = VALUES(stock),
  category = VALUES(category),
  description = VALUES(description),
  status = 'ON_SALE',
  deleted = 0,
  updated_at = NOW();

DROP TEMPORARY TABLE IF EXISTS tmp_wanxiang_food_orders;
CREATE TEMPORARY TABLE tmp_wanxiang_food_orders (
  seq INT PRIMARY KEY,
  order_no VARCHAR(64) NOT NULL,
  product_no VARCHAR(64) NOT NULL,
  sku_name VARCHAR(255) NOT NULL,
  quantity INT NOT NULL,
  ordered_at DATETIME NOT NULL,
  delivered_at DATETIME NOT NULL
);

INSERT INTO tmp_wanxiang_food_orders (seq, order_no, product_no, sku_name, quantity, ordered_at, delivered_at)
VALUES
  (1, 'TM333333330001', 'WX-FOOD-20230143-001', '500g 袋装', 1, '2026-06-30 09:15:21', '2026-07-01 15:22:08'),
  (2, 'TM333333330002', 'WX-FOOD-20230143-002', '500ml 瓶装', 2, '2026-06-30 10:28:35', '2026-07-01 16:10:42'),
  (3, 'TM333333330003', 'WX-FOOD-20230143-003', '12袋 礼盒装', 1, '2026-06-30 11:36:09', '2026-07-01 17:08:31'),
  (4, 'TM333333330004', 'WX-FOOD-20230143-004', '300g 盒装', 3, '2026-06-30 13:02:44', '2026-07-01 18:26:55'),
  (5, 'TM333333330005', 'WX-FOOD-20230143-005', '80g 罐装', 2, '2026-06-30 14:19:18', '2026-07-01 19:31:26'),
  (6, 'TM333333330006', 'WX-FOOD-20230143-006', '12粒 盒装', 1, '2026-06-30 15:47:02', '2026-07-01 20:12:09'),
  (7, 'TM333333330007', 'WX-FOOD-20230143-007', '6瓶 组合装', 1, '2026-06-30 16:35:40', '2026-07-01 20:58:36'),
  (8, 'TM333333330008', 'WX-FOOD-20230143-008', '400g 家庭装', 2, '2026-06-30 18:06:13', '2026-07-01 21:33:17'),
  (9, 'TM333333330009', 'WX-FOOD-20230143-009', '10袋 组合装', 1, '2026-06-30 19:24:29', '2026-07-01 22:18:44'),
  (10, 'TM333333330010', 'WX-FOOD-20230143-010', '1kg 袋装', 2, '2026-06-30 20:50:56', '2026-07-01 23:02:11');

DELETE d FROM twenty_mall_after_sale_dispute d
JOIN twenty_mall_after_sale a ON a.id = d.after_sale_id
JOIN twenty_mall_order o ON o.id = a.order_id
JOIN tmp_wanxiang_food_orders t ON t.order_no = o.order_no;

DELETE a FROM twenty_mall_after_sale a
JOIN twenty_mall_order o ON o.id = a.order_id
JOIN tmp_wanxiang_food_orders t ON t.order_no = o.order_no;

DELETE r FROM twenty_mall_review r
JOIN twenty_mall_order o ON o.id = r.order_id
JOIN tmp_wanxiang_food_orders t ON t.order_no = o.order_no;

DELETE i FROM twenty_mall_order_item i
JOIN twenty_mall_order o ON o.id = i.order_id
JOIN tmp_wanxiang_food_orders t ON t.order_no = o.order_no;

INSERT INTO twenty_mall_order (
  order_no, consumer_account_id, merchant_account_id, order_status, pay_status, logistics_status,
  after_sale_status, total_amount, paid_at, ordered_at, delivered_at, policy_tags, deleted
)
SELECT
  t.order_no,
  @consumer_id,
  @merchant_id,
  'COMPLETED',
  'PAID',
  'RECEIVED',
  'NONE',
  ROUND(p.price * t.quantity, 2),
  t.ordered_at,
  t.ordered_at,
  t.delivered_at,
  JSON_ARRAY('7天无理由退货', '运费险'),
  0
FROM tmp_wanxiang_food_orders t
JOIN twenty_mall_product p ON p.product_no = t.product_no
ON DUPLICATE KEY UPDATE
  consumer_account_id = VALUES(consumer_account_id),
  merchant_account_id = VALUES(merchant_account_id),
  order_status = 'COMPLETED',
  pay_status = 'PAID',
  logistics_status = 'RECEIVED',
  after_sale_status = 'NONE',
  total_amount = VALUES(total_amount),
  paid_at = VALUES(paid_at),
  ordered_at = VALUES(ordered_at),
  delivered_at = VALUES(delivered_at),
  policy_tags = VALUES(policy_tags),
  deleted = 0,
  updated_at = NOW();

INSERT INTO twenty_mall_order_item (
  order_id, product_id, product_name, sku_name, product_image_url, unit_price, quantity, total_amount,
  after_sale_status, deleted
)
SELECT
  o.id,
  p.id,
  p.product_name,
  t.sku_name,
  p.product_image_url,
  p.price,
  t.quantity,
  ROUND(p.price * t.quantity, 2),
  'NONE',
  0
FROM tmp_wanxiang_food_orders t
JOIN twenty_mall_order o ON o.order_no = t.order_no
JOIN twenty_mall_product p ON p.product_no = t.product_no;

DROP TEMPORARY TABLE IF EXISTS tmp_wanxiang_food_orders;
