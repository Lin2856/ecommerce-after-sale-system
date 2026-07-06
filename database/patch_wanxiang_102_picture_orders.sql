USE ecommerce_after_sale;
SET NAMES utf8mb4;

DELETE oi
FROM twenty_mall_order_item oi
JOIN twenty_mall_order o ON o.id = oi.order_id
WHERE o.order_no LIKE 'WX102%';

DELETE FROM twenty_mall_order
WHERE order_no LIKE 'WX102%';

DELETE p
FROM twenty_mall_product p
JOIN twenty_mall_account ma ON ma.id = p.merchant_account_id
WHERE ma.platform_code = 'TWENTY_MALL'
  AND ma.account_no BETWEEN '10270001' AND '10270006';

DELETE FROM platform_account_binding
WHERE platform_code = 'TWENTY_MALL'
  AND (
    secondary_account_no BETWEEN '10260001' AND '10260050'
    OR secondary_account_no BETWEEN '10270001' AND '10270006'
  );

DELETE FROM twenty_mall_account
WHERE platform_code = 'TWENTY_MALL'
  AND (
    account_no BETWEEN '10260001' AND '10260050'
    OR account_no BETWEEN '10270001' AND '10270006'
  );

DROP PROCEDURE IF EXISTS seed_wanxiang_102_picture_orders;

DELIMITER //
CREATE PROCEDURE seed_wanxiang_102_picture_orders()
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
  DECLARE display_name_value VARCHAR(128);
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
  DECLARE primary_consumer_id BIGINT;
  DECLARE primary_merchant_id BIGINT;
  DECLARE ordered_time DATETIME;
  DECLARE chars VARCHAR(80) DEFAULT 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  SELECT id INTO primary_consumer_id
  FROM primary_account
  WHERE account_no = '13338907583' AND account_type = 'CONSUMER' AND deleted = 0
  LIMIT 1;

  SELECT id INTO primary_merchant_id
  FROM primary_account
  WHERE account_no = '13338907682' AND account_type = 'MERCHANT' AND deleted = 0
  LIMIT 1;

  WHILE i <= 50 DO
    SET consumer_no = CONCAT('1026', LPAD(i, 4, '0'));
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
    SET display_name_value = ELT(MOD(i - 1, 30) + 1,
      '一杯乌龙', '橘子星河', '山风邮差', '栗色日记', '浅海来信',
      '落日小站', '云朵航班', '青柠汽水', '慢热薄荷', '半糖月光',
      '北窗听雨', '雾里看花', '松间小路', '小满晴天', '白桃旅人',
      '南街晚风', '玫瑰小岛', '蓝莓信箱', '清晨麦芽', '柚子茶馆',
      '银杏树下', '星野便利店', '海盐奶盖', '晴日收纳', '风铃旧梦',
      '草莓回声', '茉莉书签', '小鹿慢跑', '橙光港口', '月台拾光'
    );

    INSERT INTO twenty_mall_account (
      platform_code, account_no, password_plain, account_role, display_name, phone, bind_status, status, deleted
    ) VALUES (
      'TWENTY_MALL',
      consumer_no,
      password_value,
      'CONSUMER',
      display_name_value,
      NULL,
      'BOUND',
      'ACTIVE',
      0
    );

    IF primary_consumer_id IS NOT NULL THEN
      INSERT INTO platform_account_binding (
        primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
      ) VALUES (
        primary_consumer_id, 'TWENTY_MALL', '万象商城', consumer_no, 'CONSUMER', 'BOUND', NOW(), 0
      );
    END IF;
    SET i = i + 1;
  END WHILE;

  SET i = 1;
  WHILE i <= 6 DO
    SET merchant_no = CONCAT('1027', LPAD(i, 4, '0'));
    SET shop_name_value = ELT(i,
      '墨森文具生活馆',
      '云织童装鞋履店',
      '鲜港生鲜优选店',
      '森居电器家具馆',
      '日用百货严选店',
      '食光零食铺'
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
      'TWENTY_MALL',
      merchant_no,
      password_value,
      'MERCHANT',
      shop_name_value,
      NULL,
      'BOUND',
      'ACTIVE',
      0
    );

    IF primary_merchant_id IS NOT NULL THEN
      INSERT INTO platform_account_binding (
        primary_account_id, platform_code, platform_name, secondary_account_no, secondary_account_role, bind_status, bound_at, deleted
      ) VALUES (
        primary_merchant_id, 'TWENTY_MALL', '万象商城', merchant_no, 'MERCHANT', 'BOUND', NOW(), 0
      );
    END IF;

    SET j = 1;
    WHILE j <= 10 DO
      SET category_value = ELT(i, '文具办公', '服装鞋履', '生鲜水产', '家电家具', '日用百货', '休闲食品');
      SET product_no_value = CONCAT('WX102-P-', LPAD(i, 2, '0'), '-', LPAD(j, 2, '0'));
      SET product_name_value = CASE i
        WHEN 1 THEN ELT(j,
          '加厚便签纸便利贴办公学习记事本',
          '儿童卡通文具套装铅笔橡皮尺子组合',
          '彩色长尾夹票据夹办公文件夹子',
          '学生水彩笔彩笔套装绘画涂鸦笔',
          '文具盲盒学习用品惊喜套装',
          '顺滑签字笔黑色中性笔办公考试用笔',
          '绿色计算器学生办公大按键计算器',
          '桌面计算器财务办公太阳能计算器',
          '经典钢笔练字书写商务钢笔',
          '礼盒装钢笔套装学生成人书写套装'
        )
        WHEN 2 THEN ELT(j,
          '儿童纯棉短袖夏季透气T恤',
          '婴儿连体衣套装柔软亲肤宝宝衣服',
          '百搭低帮板鞋学生休闲运动鞋',
          '商务正装皮鞋男士通勤黑色皮鞋',
          '纯色短袖T恤男女同款基础款',
          '法式碎花连衣裙夏季收腰裙子',
          '轻便缓震运动鞋跑步训练鞋',
          '户外速干裤薄款休闲长裤',
          '儿童印花短袖T恤夏日换洗装',
          '透气网面运动鞋日常通勤款'
        )
        WHEN 3 THEN ELT(j,
          '冷冻大黄鱼整条海鲜水产家庭装',
          '舟山带鱼段冷冻海鲜香煎食材',
          '烧烤食材组合牛羊肉串家庭露营装',
          '原切牛排冷冻西餐煎烤牛肉',
          '乳山生蚝鲜活大个海鲜贝类',
          '皮皮虾鲜活冷链海捕虾蛄',
          '冷冻虾仁去壳青虾仁炒菜火锅',
          '进口车厘子新鲜水果礼盒装',
          '鲜活鲈鱼清蒸海鲜水产',
          '波士顿龙虾鲜活海鲜大龙虾'
        )
        WHEN 4 THEN ELT(j,
          '现代简约双人床卧室软包床',
          '大吸力抽油烟机厨房家用油烟机',
          '北欧实木餐桌书桌家用桌子',
          '不锈钢热水壶家用快速烧水壶',
          '储水式电热水器家用节能热水器',
          '大功率电磁炉家用火锅炒菜炉',
          '高清智能电视客厅大屏电视机',
          '节能冷暖空调挂机卧室空调',
          '客厅小户型茶几简约储物茶几',
          '推拉门衣柜卧室大容量收纳柜'
        )
        WHEN 5 THEN ELT(j,
          '户外点火喷火枪厨房烘焙烧烤工具',
          '偏光太阳镜墨镜防紫外线驾驶眼镜',
          '防风打火机金属便携点火器',
          '家用抽纸整箱卫生纸面巾纸',
          '粉色电动车头盔四季通用安全帽',
          '家庭洗衣肥皂去渍清洁皂',
          '夏季草帽遮阳帽户外防晒帽',
          '大檐遮阳帽女夏季防晒太阳帽',
          '黄色电动车头盔半盔安全帽',
          '黑色电动车头盔男女通用骑行帽'
        )
        ELSE ELT(j,
          '传统核桃酥糕点老人儿童零食',
          '榴莲饼早餐点心酥皮榴莲味糕点',
          '手工牛轧糖花生奶香软糖',
          '上海葱油拌面速食面条方便早餐',
          '奶油蛋糕下午茶甜品生日小蛋糕',
          '酱牛肉熟食卤味真空包装',
          '香脆饼干办公室休闲零食',
          '香菇素菜包早餐包子速冻面点',
          '卤香鸡腿即食熟食真空小吃',
          '黄油饼干曲奇礼盒休闲零食'
        )
      END;
      SET image_value = CONCAT('/assets/products/wanxiang-102/wx102-', LPAD(i, 2, '0'), '-', LPAD(j, 2, '0'), '.png');
      SET price_value = CASE i
        WHEN 1 THEN ELT(j, 12.90, 39.90, 16.80, 29.90, 19.90, 24.90, 35.90, 32.90, 58.00, 99.00)
        WHEN 2 THEN ELT(j, 49.00, 88.00, 129.00, 239.00, 39.00, 168.00, 199.00, 119.00, 55.00, 189.00)
        WHEN 3 THEN ELT(j, 78.00, 49.90, 128.00, 99.00, 68.00, 89.00, 59.90, 168.00, 45.00, 238.00)
        WHEN 4 THEN ELT(j, 1599.00, 1299.00, 699.00, 89.00, 1099.00, 199.00, 2399.00, 2999.00, 399.00, 1899.00)
        WHEN 5 THEN ELT(j, 29.90, 79.00, 19.90, 39.90, 89.00, 9.90, 26.90, 35.90, 79.00, 85.00)
        ELSE ELT(j, 29.90, 35.90, 42.90, 19.90, 58.00, 69.00, 24.90, 32.90, 16.90, 39.90)
      END;

      SELECT id INTO merchant_id_value
      FROM twenty_mall_account
      WHERE platform_code = 'TWENTY_MALL' AND account_no = merchant_no AND account_role = 'MERCHANT'
      LIMIT 1;

      INSERT INTO twenty_mall_product (
        merchant_account_id, product_no, product_name, product_image_url, price, stock, category, description, status, deleted
      ) VALUES (
        merchant_id_value,
        product_no_value,
        product_name_value,
        image_value,
        price_value,
        100 + FLOOR(RAND() * 500),
        category_value,
        CONCAT(product_name_value, '，来自万象商城', shop_name_value, '。商品图片来源于本批次真实商品素材，支持按订单发起售后和评价。'),
        'ON_SALE',
        0
      );
      SET j = j + 1;
    END WHILE;
    SET i = i + 1;
  END WHILE;

  SET i = 1;
  WHILE i <= 50 DO
    SET consumer_no = CONCAT('1026', LPAD(i, 4, '0'));
    SELECT id INTO consumer_id_value
    FROM twenty_mall_account
    WHERE platform_code = 'TWENTY_MALL' AND account_no = consumer_no AND account_role = 'CONSUMER'
    LIMIT 1;

    SET order_count = 6 + FLOOR(RAND() * 10);
    SET order_index = 1;
    WHILE order_index <= order_count DO
      SET merchant_index = 1 + FLOOR(RAND() * 6);
      SET product_index = 1 + FLOOR(RAND() * 10);
      SET merchant_no = CONCAT('1027', LPAD(merchant_index, 4, '0'));
      SET product_no_value = CONCAT('WX102-P-', LPAD(merchant_index, 2, '0'), '-', LPAD(product_index, 2, '0'));
      SELECT id INTO merchant_id_value
      FROM twenty_mall_account
      WHERE platform_code = 'TWENTY_MALL' AND account_no = merchant_no AND account_role = 'MERCHANT'
      LIMIT 1;
      SELECT id, price, product_name, product_image_url INTO product_id_value, price_value, product_name_value, image_value
      FROM twenty_mall_product
      WHERE product_no = product_no_value
      LIMIT 1;

      SET quantity_value = 1 + FLOOR(RAND() * 3);
      SET order_no_value = CONCAT('WX102', LPAD(i, 4, '0'), LPAD(order_index, 3, '0'));
      SET ordered_time = DATE_SUB(NOW(), INTERVAL (FLOOR(RAND() * 60) + order_index) DAY);
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
        CASE WHEN merchant_index = 3
          THEN JSON_ARRAY('生鲜商品不支持七天无理由', '冷链配送', '平台保障')
          ELSE JSON_ARRAY('7天无理由退货', '运费险', '平台保障')
        END,
        0
      );
      SET order_id_value = LAST_INSERT_ID();
      SET sku_value = CASE merchant_index
        WHEN 1 THEN ELT(1 + FLOOR(RAND() * 4), '单件装 / 默认款', '双件装 / 常规款', '学习套装 / 混色', '办公套装 / 黑色')
        WHEN 2 THEN ELT(1 + FLOOR(RAND() * 4), 'M码 / 基础色', 'L码 / 清爽色', '儿童款 / 随机色', '成人款 / 黑白色')
        WHEN 3 THEN ELT(1 + FLOOR(RAND() * 4), '冷冻装 / 500g', '冷链装 / 1kg', '家庭装 / 2份', '礼盒装 / 顺丰冷链')
        WHEN 4 THEN ELT(1 + FLOOR(RAND() * 4), '经典款 / 白色', '升级款 / 银色', '家用款 / 标准版', '大容量 / 高配版')
        WHEN 5 THEN ELT(1 + FLOOR(RAND() * 4), '单件装 / 默认色', '两件装 / 混色', '家庭装 / 实惠款', '户外款 / 加固版')
        ELSE ELT(1 + FLOOR(RAND() * 4), '原味 / 1袋', '礼盒装 / 组合味', '家庭装 / 3袋', '独立包装 / 便携装')
      END;
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

CALL seed_wanxiang_102_picture_orders();

DROP PROCEDURE IF EXISTS seed_wanxiang_102_picture_orders;
