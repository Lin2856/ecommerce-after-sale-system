DROP TEMPORARY TABLE IF EXISTS tmp_yuegou_category_keyword_names;
CREATE TEMPORARY TABLE tmp_yuegou_category_keyword_names (
  product_no VARCHAR(64) PRIMARY KEY,
  product_name VARCHAR(255) NOT NULL
);

INSERT INTO tmp_yuegou_category_keyword_names (product_no, product_name) VALUES
('YG-P-01-01','护眼台灯 奶油风充电书桌阅读灯'),
('YG-P-01-02','床头台灯 北欧简约卧室暖光小夜灯'),
('YG-P-01-03','学习台灯 儿童书桌护眼可调光阅读灯'),
('YG-P-01-04','装饰台灯 现代轻奢金属客厅书房灯'),
('YG-P-01-05','折叠台灯 宿舍便携LED学习灯'),
('YG-P-01-06','护眼台灯 智能感应三色调光插电款'),
('YG-P-01-07','长臂台灯 极简白色办公绘图工作灯'),
('YG-P-01-08','床头台灯 复古木纹卧室暖光阅读灯'),
('YG-P-01-09','护眼台灯 无线充电带闹钟显示屏'),
('YG-P-01-10','学习台灯 大光面儿童书桌专业护眼灯'),
('YG-P-08-01','机械键盘 客制化热插拔办公游戏键盘'),
('YG-P-08-02','机械键盘 三模无线低延迟长续航款'),
('YG-P-08-03','机械键盘 奶油风女生办公打字键盘'),
('YG-P-08-04','机械键盘 静音轴宿舍办公低噪款'),
('YG-P-08-05','机械键盘 RGB背光电竞游戏有线键盘'),
('YG-P-08-06','蓝牙键盘 超薄便携平板笔记本键盘'),
('YG-P-08-07','机械键盘 87键无线热升华键帽款'),
('YG-P-08-08','办公键盘 全尺寸数字区财务打字款'),
('YG-P-08-09','蓝牙键盘 复古圆帽多设备切换款'),
('YG-P-08-10','平板键盘 磁吸保护套学习办公款');

UPDATE twenty_mall_product p
JOIN tmp_yuegou_category_keyword_names n ON n.product_no = p.product_no
JOIN twenty_mall_account ma ON ma.id = p.merchant_account_id
SET p.product_name = n.product_name,
    p.description = CONCAT(n.product_name, '，由', ma.display_name, '提供。标题已保留明确商品类目，便于消费者在订单和详情页快速识别商品。'),
    p.updated_at = NOW()
WHERE ma.platform_code = 'YUEGOU_MARKET';

UPDATE twenty_mall_order_item oi
JOIN twenty_mall_product p ON p.id = oi.product_id
JOIN tmp_yuegou_category_keyword_names n ON n.product_no = p.product_no
JOIN twenty_mall_account ma ON ma.id = p.merchant_account_id
SET oi.product_name = n.product_name,
    oi.updated_at = NOW()
WHERE ma.platform_code = 'YUEGOU_MARKET';

DROP TEMPORARY TABLE IF EXISTS tmp_yuegou_category_keyword_names;
