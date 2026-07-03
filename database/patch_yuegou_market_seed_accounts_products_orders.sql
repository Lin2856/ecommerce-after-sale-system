DELETE oi
FROM twenty_mall_order_item oi
JOIN twenty_mall_order o ON o.id = oi.order_id
WHERE o.order_no LIKE 'YG2026%';

DELETE FROM twenty_mall_order
WHERE order_no LIKE 'YG2026%';

DELETE p
FROM twenty_mall_product p
JOIN twenty_mall_account ma ON ma.id = p.merchant_account_id
WHERE ma.platform_code = 'YUEGOU_MARKET'
  AND ma.account_no BETWEEN '20270001' AND '20270010';

DELETE FROM platform_account_binding
WHERE platform_code = 'YUEGOU_MARKET'
  AND (
    secondary_account_no BETWEEN '20260001' AND '20260050'
    OR secondary_account_no BETWEEN '20270001' AND '20270010'
  );

DELETE FROM twenty_mall_account
WHERE platform_code = 'YUEGOU_MARKET'
  AND (
    account_no BETWEEN '20260001' AND '20260050'
    OR account_no BETWEEN '20270001' AND '20270010'
  );

DROP PROCEDURE IF EXISTS seed_yuegou_market_demo;

DELIMITER //
CREATE PROCEDURE seed_yuegou_market_demo()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE j INT DEFAULT 1;
  DECLARE merchant_index INT DEFAULT 1;
  DECLARE product_index INT DEFAULT 1;
  DECLARE order_index INT DEFAULT 1;
  DECLARE order_count INT DEFAULT 0;
  DECLARE quantity_value INT DEFAULT 1;
  DECLARE consumer_no VARCHAR(64);
  DECLARE merchant_no VARCHAR(64);
  DECLARE product_no_value VARCHAR(64);
  DECLARE password_value VARCHAR(16);
  DECLARE shop_name_value VARCHAR(128);
  DECLARE category_value VARCHAR(64);
  DECLARE product_name_value VARCHAR(255);
  DECLARE image_value VARCHAR(512);
  DECLARE sku_value VARCHAR(255);
  DECLARE price_value DECIMAL(12,2);
  DECLARE order_no_value VARCHAR(64);
  DECLARE consumer_id_value BIGINT;
  DECLARE merchant_id_value BIGINT;
  DECLARE product_id_value BIGINT;
  DECLARE order_id_value BIGINT;
  DECLARE ordered_time DATETIME;
  DECLARE chars VARCHAR(80) DEFAULT 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  WHILE i <= 50 DO
    SET consumer_no = CONCAT('2026', LPAD(i, 4, '0'));
    SET password_value = CONCAT(
      CHAR(65 + FLOOR(RAND() * 26)),
      CHAR(97 + FLOOR(RAND() * 26)),
      FLOOR(RAND() * 10),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1)
    );
    INSERT INTO twenty_mall_account (
      platform_code, account_no, password_plain, account_role, display_name, phone, bind_status, status, deleted
    ) VALUES (
      'YUEGOU_MARKET',
      consumer_no,
      password_value,
      'CONSUMER',
      ELT(MOD(i - 1, 30) + 1,
        '鹿岛来信', '小满有风', '青柚山谷', '星野慢递', '橙子月台',
        '半夏听雨', '云朵汽水', '南风旧巷', '海盐薄荷', '晴日收藏',
        '乌龙茶冻', '月光便利店', '松果小站', '蓝莓日落', '栗子邮差',
        '晚星漫游', '白桃海岸', '风铃小院', '柠檬树影', '山茶未眠',
        '薄雾书签', '北窗橘光', '草莓电台', '银杏旅人', '清晨小鹿',
        '茉莉星球', '雨后奶盖', '云边拾光', '小熊日记', '落日航线'
      ),
      NULL,
      'UNBOUND',
      'ACTIVE',
      0
    );
    SET i = i + 1;
  END WHILE;

  SET i = 1;
  WHILE i <= 10 DO
    SET merchant_no = CONCAT('2027', LPAD(i, 4, '0'));
    SET shop_name_value = ELT(i,
      '光屿灯具生活馆',
      '棉境家纺旗舰店',
      '木序收纳家居店',
      '坐感研究所',
      '杯中日常专卖店',
      '声野数码影音店',
      '行囊城市箱包店',
      '敲击星球外设店',
      '晴雨之间生活馆',
      '灵点击数码配件店'
    );
    SET password_value = CONCAT(
      CHAR(65 + FLOOR(RAND() * 26)),
      CHAR(97 + FLOOR(RAND() * 26)),
      FLOOR(RAND() * 10),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1),
      SUBSTRING(chars, FLOOR(RAND() * 62) + 1, 1)
    );
    INSERT INTO twenty_mall_account (
      platform_code, account_no, password_plain, account_role, display_name, phone, bind_status, status, deleted
    ) VALUES (
      'YUEGOU_MARKET',
      merchant_no,
      password_value,
      'MERCHANT',
      shop_name_value,
      NULL,
      'UNBOUND',
      'ACTIVE',
      0
    );

    SET j = 1;
    WHILE j <= 10 DO
      SET category_value = ELT(i, '台灯', '床单', '挂衣架', '椅子', '水杯', '耳机', '背包', '键盘', '雨伞', '鼠标');
      SET product_no_value = CONCAT('YG-P-', LPAD(i, 2, '0'), '-', LPAD(j, 2, '0'));
      SET product_name_value = CONCAT(
        '悦购',
        ELT(i,
          '柔光护眼台灯', '亲肤纯棉床单', '落地多功能挂衣架', '人体工学休闲椅', '便携保温水杯',
          '降噪蓝牙耳机', '城市通勤背包', '机械键盘', '晴雨两用伞', '无线静音鼠标'
        ),
        ' ',
        LPAD(j, 2, '0'),
        '款'
      );
      SET image_value = CONCAT('/assets/products/yuegou-market/yuegou-', LPAD(i, 2, '0'), '-', LPAD(j, 2, '0'), '.png');
      SET price_value = ELT(i, 129.00, 89.00, 69.00, 239.00, 59.00, 199.00, 159.00, 299.00, 49.00, 89.00) + (j * 3);
      SELECT id INTO merchant_id_value
      FROM twenty_mall_account
      WHERE platform_code = 'YUEGOU_MARKET' AND account_no = merchant_no AND account_role = 'MERCHANT'
      LIMIT 1;
      INSERT INTO twenty_mall_product (
        merchant_account_id, product_no, product_name, product_image_url, price, stock, category, description, status, deleted
      ) VALUES (
        merchant_id_value,
        product_no_value,
        product_name_value,
        image_value,
        price_value,
        300 + FLOOR(RAND() * 700),
        category_value,
        CONCAT(product_name_value, '，来自悦购集市', shop_name_value, '。商品支持按订单发起售后，适用于日常使用、家庭场景和礼品采购。'),
        'ON_SALE',
        0
      );
      SET j = j + 1;
    END WHILE;
    SET i = i + 1;
  END WHILE;

  SET i = 1;
  WHILE i <= 50 DO
    SET consumer_no = CONCAT('2026', LPAD(i, 4, '0'));
    SELECT id INTO consumer_id_value
    FROM twenty_mall_account
    WHERE platform_code = 'YUEGOU_MARKET' AND account_no = consumer_no AND account_role = 'CONSUMER'
    LIMIT 1;
    SET order_count = 6 + FLOOR(RAND() * 10);
    SET order_index = 1;
    WHILE order_index <= order_count DO
      SET merchant_index = 1 + FLOOR(RAND() * 10);
      SET product_index = 1 + FLOOR(RAND() * 10);
      SET merchant_no = CONCAT('2027', LPAD(merchant_index, 4, '0'));
      SET product_no_value = CONCAT('YG-P-', LPAD(merchant_index, 2, '0'), '-', LPAD(product_index, 2, '0'));
      SELECT id INTO merchant_id_value
      FROM twenty_mall_account
      WHERE platform_code = 'YUEGOU_MARKET' AND account_no = merchant_no AND account_role = 'MERCHANT'
      LIMIT 1;
      SELECT id, price, product_name, product_image_url INTO product_id_value, price_value, product_name_value, image_value
      FROM twenty_mall_product
      WHERE product_no = product_no_value
      LIMIT 1;
      SET quantity_value = 1 + FLOOR(RAND() * 3);
      SET order_no_value = CONCAT('YG', consumer_no, LPAD(order_index, 3, '0'));
      SET ordered_time = DATE_SUB(NOW(), INTERVAL (FLOOR(RAND() * 45) + order_index) DAY);
      INSERT INTO twenty_mall_order (
        order_no, consumer_account_id, merchant_account_id, order_status, pay_status, logistics_status,
        after_sale_status, total_amount, paid_at, ordered_at, delivered_at, policy_tags, deleted
      ) VALUES (
        order_no_value,
        consumer_id_value,
        merchant_id_value,
        'COMPLETED',
        'PAID',
        'DELIVERED',
        'NONE',
        price_value * quantity_value,
        ordered_time,
        ordered_time,
        DATE_ADD(ordered_time, INTERVAL (2 + FLOOR(RAND() * 4)) DAY),
        JSON_ARRAY('7天无理由退货', '运费险', '平台保障'),
        0
      );
      SET order_id_value = LAST_INSERT_ID();
      SET sku_value = CONCAT(
        ELT(1 + FLOOR(RAND() * 4), '经典款', '升级款', '轻享款', '家庭装'),
        ' / ',
        ELT(1 + FLOOR(RAND() * 4), '象牙白', '雾霾蓝', '暖沙色', '石墨灰')
      );
      INSERT INTO twenty_mall_order_item (
        order_id, product_id, product_name, sku_name, product_image_url, unit_price, quantity, total_amount, after_sale_status, deleted
      ) VALUES (
        order_id_value,
        product_id_value,
        product_name_value,
        sku_value,
        image_value,
        price_value,
        quantity_value,
        price_value * quantity_value,
        'NONE',
        0
      );
      SET order_index = order_index + 1;
    END WHILE;
    SET i = i + 1;
  END WHILE;
END//
DELIMITER ;

CALL seed_yuegou_market_demo();

DROP PROCEDURE IF EXISTS seed_yuegou_market_demo;
