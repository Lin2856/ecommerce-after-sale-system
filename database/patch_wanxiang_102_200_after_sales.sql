USE ecommerce_after_sale;
SET NAMES utf8mb4;

DROP TEMPORARY TABLE IF EXISTS tmp_wanxiang_102_after_sale_orders;
CREATE TEMPORARY TABLE tmp_wanxiang_102_after_sale_orders AS
SELECT *
FROM (
  SELECT
    o.id AS order_id,
    o.order_no,
    o.consumer_account_id,
    o.total_amount,
    oi.id AS order_item_id,
    oi.product_id,
    oi.product_name,
    p.category,
    ROW_NUMBER() OVER (ORDER BY MD5(CONCAT(o.order_no, ':wanxiang-102-after-sale'))) AS rn
  FROM twenty_mall_order o
  JOIN twenty_mall_account merchant
    ON merchant.id = o.merchant_account_id
   AND merchant.platform_code = 'TWENTY_MALL'
   AND merchant.account_role = 'MERCHANT'
   AND merchant.account_no BETWEEN '10270001' AND '10270006'
   AND merchant.deleted = 0
  JOIN twenty_mall_order_item oi
    ON oi.order_id = o.id
   AND oi.deleted = 0
  JOIN twenty_mall_product p
    ON p.id = oi.product_id
   AND p.deleted = 0
  WHERE o.deleted = 0
    AND o.order_no LIKE 'WX102%'
) picked
WHERE picked.rn <= 200;

DELETE review
FROM twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
WHERE o.order_no LIKE 'WX102%';

DELETE after_sale
FROM twenty_mall_after_sale after_sale
JOIN twenty_mall_order o ON o.id = after_sale.order_id
WHERE o.order_no LIKE 'WX102%';

UPDATE twenty_mall_order o
SET o.after_sale_status = 'NONE',
    o.order_status = 'COMPLETED',
    o.pay_status = 'PAID',
    o.updated_at = NOW()
WHERE o.order_no LIKE 'WX102%'
  AND o.deleted = 0;

UPDATE twenty_mall_order_item oi
JOIN twenty_mall_order o ON o.id = oi.order_id
SET oi.after_sale_status = 'NONE',
    oi.updated_at = NOW()
WHERE o.order_no LIKE 'WX102%'
  AND oi.deleted = 0;

INSERT INTO twenty_mall_after_sale (
  after_sale_no,
  order_id,
  order_item_id,
  after_sale_type,
  reason_type,
  description,
  requested_amount,
  status,
  return_tracking_no,
  return_shipped_at,
  created_at,
  updated_at,
  deleted
)
SELECT
  CONCAT('WXAS102', SUBSTRING(order_no, 6), LPAD(MOD(rn, 1000), 3, '0')) AS after_sale_no,
  order_id,
  order_item_id,
  CASE
    WHEN category IN ('生鲜水产', '休闲食品') THEN 'REFUND_ONLY'
    WHEN MOD(rn, 6) IN (1, 3) THEN 'REFUND_ONLY'
    ELSE 'RETURN_REFUND'
  END AS after_sale_type,
  CASE
    WHEN category IN ('生鲜水产', '休闲食品') THEN 'PRODUCT_QUALITY'
    WHEN category IN ('家电家具', '文具办公') THEN 'PRODUCT_QUALITY'
    WHEN category IN ('服装鞋履', '日用百货') THEN 'WRONG_GOODS'
    ELSE 'OTHER'
  END AS reason_type,
  CASE category
    WHEN '文具办公' THEN CONCAT(product_name, '收到后外包装有挤压痕迹，试用时发现细节做工和页面描述略有差距，希望商家协助售后处理。')
    WHEN '服装鞋履' THEN CONCAT(product_name, '尺码和预期不太一致，部分走线细节也比较明显，穿着体验受影响，申请售后。')
    WHEN '生鲜水产' THEN CONCAT(product_name, '到货后冰袋已经基本融化，食材新鲜度不如预期，考虑到生鲜特殊性申请仅退款处理。')
    WHEN '家电家具' THEN CONCAT(product_name, '安装或试用后发现功能细节存在问题，和正常使用预期不一致，申请售后处理。')
    WHEN '日用百货' THEN CONCAT(product_name, '实物存在轻微瑕疵，和详情页展示有差异，希望商家给出处理方案。')
    WHEN '休闲食品' THEN CONCAT(product_name, '收到后包装状态一般，口感或保质信息让人不太放心，申请售后处理。')
    ELSE CONCAT(product_name, '收到后和预期不一致，申请售后处理。')
  END AS description,
  CASE
    WHEN category IN ('生鲜水产', '休闲食品') THEN ROUND(total_amount * 0.7, 2)
    WHEN MOD(rn, 6) IN (1, 3) THEN ROUND(total_amount * 0.45, 2)
    ELSE total_amount
  END AS requested_amount,
  CASE
    WHEN MOD(rn, 6) = 0 THEN 'PENDING_REVIEW'
    WHEN MOD(rn, 6) = 1 THEN 'PROCESSING'
    WHEN MOD(rn, 6) = 2 THEN 'WAITING_RETURN'
    WHEN MOD(rn, 6) = 3 THEN 'REJECTED'
    WHEN MOD(rn, 6) = 4 THEN 'RETURN_SHIPPED'
    ELSE 'COMPLETED'
  END AS status,
  CASE
    WHEN MOD(rn, 6) IN (4, 5)
      THEN CONCAT('YT', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(rn, 6, '0'))
    ELSE NULL
  END AS return_tracking_no,
  CASE
    WHEN MOD(rn, 6) IN (4, 5)
      THEN DATE_SUB(NOW(), INTERVAL (MOD(rn, 4) + 1) DAY)
    ELSE NULL
  END AS return_shipped_at,
  CASE
    WHEN MOD(rn, 6) = 0 THEN DATE_SUB(NOW(), INTERVAL (MOD(rn, 18) + 1) HOUR)
    ELSE DATE_SUB(NOW(), INTERVAL (MOD(rn, 18) + 2) DAY)
  END AS created_at,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 3) DAY) AS updated_at,
  0 AS deleted
FROM tmp_wanxiang_102_after_sale_orders;

UPDATE twenty_mall_order o
JOIN twenty_mall_after_sale after_sale
  ON after_sale.order_id = o.id
 AND after_sale.deleted = 0
SET o.after_sale_status = after_sale.status,
    o.order_status = CASE WHEN after_sale.status = 'COMPLETED' THEN 'REFUNDED' ELSE o.order_status END,
    o.pay_status = CASE WHEN after_sale.status = 'COMPLETED' THEN 'REFUNDED' ELSE o.pay_status END,
    o.updated_at = NOW()
WHERE o.order_no LIKE 'WX102%'
  AND o.deleted = 0;

UPDATE twenty_mall_order_item oi
JOIN twenty_mall_after_sale after_sale
  ON after_sale.order_item_id = oi.id
 AND after_sale.deleted = 0
JOIN twenty_mall_order o ON o.id = oi.order_id
SET oi.after_sale_status = after_sale.status,
    oi.updated_at = NOW()
WHERE o.order_no LIKE 'WX102%'
  AND oi.deleted = 0;

INSERT INTO twenty_mall_review (
  order_id,
  product_id,
  consumer_account_id,
  product_score,
  service_score,
  content,
  status,
  reviewed_at,
  created_at,
  updated_at,
  deleted
)
SELECT
  order_id,
  product_id,
  consumer_account_id,
  CASE
    WHEN MOD(rn, 20) IN (0, 1, 2, 3, 4, 5, 6) THEN 5
    WHEN MOD(rn, 20) IN (7, 8, 9, 10, 11, 12) THEN 4
    WHEN MOD(rn, 20) IN (13, 14, 15, 16) THEN 3
    WHEN MOD(rn, 20) IN (17, 18) THEN 2
    ELSE 1
  END AS product_score,
  CASE
    WHEN MOD(rn, 20) IN (0, 1, 2, 3, 7, 8) THEN 5
    WHEN MOD(rn, 20) IN (4, 5, 6, 9, 10, 11, 12) THEN 4
    WHEN MOD(rn, 20) IN (13, 14, 15, 16) THEN 3
    WHEN MOD(rn, 20) IN (17, 18) THEN 2
    ELSE 1
  END AS service_score,
  CONCAT(
    CASE category
      WHEN '文具办公' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '做工比想象中细致，日常学习和办公都够用，包装也比较整齐。'
          WHEN 1 THEN '基础功能没问题，但个别边角处理一般，近看能发现一点毛糙。'
          WHEN 2 THEN '颜色和图片接近，使用起来顺手，放在桌面上也不占地方。'
          WHEN 3 THEN '收到后马上试了一下，能满足日常需求，不过质感不算特别高级。'
          WHEN 4 THEN '数量和规格都对，孩子上学用比较合适，性价比还可以。'
          WHEN 5 THEN '有轻微压痕但不影响使用，希望发货前质检能再仔细一点。'
          WHEN 6 THEN '用起来比较顺滑，书写或整理文件时没有明显卡顿。'
          ELSE '实物和预期差距不大，适合普通办公学习场景。'
        END
      )
      WHEN '服装鞋履' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '上身或上脚效果自然，尺码基本合适，日常穿着比较舒服。'
          WHEN 1 THEN '面料手感还行，但线头稍微多了一点，细节做工可以继续提升。'
          WHEN 2 THEN '版型和图片接近，颜色没有明显色差，搭配日常衣服很方便。'
          WHEN 3 THEN '尺码偏差比预想大一点，穿着体验受影响，所以只给中评。'
          WHEN 4 THEN '鞋底或面料的舒适度不错，走路一段时间没有明显磨脚。'
          WHEN 5 THEN '包装普通，商品本身没有破损，但细节不够精致。'
          WHEN 6 THEN '买来换季穿正合适，透气性和重量都能接受。'
          ELSE '实物能穿，但没有详情页看起来那么有质感。'
        END
      )
      WHEN '生鲜水产' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '冷链包装完整，打开后新鲜度不错，家里人吃完反馈可以。'
          WHEN 1 THEN '冰袋到货时已经化了一部分，食材状态一般，体验不算稳定。'
          WHEN 2 THEN '分量基本够，处理起来方便，适合家庭临时加餐。'
          WHEN 3 THEN '新鲜度没有达到预期，气味比平时买的重一些，这点比较失望。'
          WHEN 4 THEN '个头和页面描述接近，烹饪后口感还可以。'
          WHEN 5 THEN '包装没有漏液，但温控感觉一般，希望冷链再加强。'
          WHEN 6 THEN '整体能接受，适合对时效要求不太极端的购买场景。'
          ELSE '这类商品很看配送状态，本次到货表现中规中矩。'
        END
      )
      WHEN '家电家具' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '安装后使用稳定，功能符合描述，放在家里整体效果不错。'
          WHEN 1 THEN '外观还可以，但安装或试用时发现小细节不够顺手。'
          WHEN 2 THEN '材质和重量都比较扎实，日常家用基本够。'
          WHEN 3 THEN '功能能用，但噪音或接缝细节比预期明显，所以评价一般。'
          WHEN 4 THEN '包装保护到位，没有明显磕碰，客服说明也比较清楚。'
          WHEN 5 THEN '实际尺寸要仔细确认，和家里空间搭配时需要多量一下。'
          WHEN 6 THEN '使用几天暂时没发现大问题，后续耐用度还要继续看。'
          ELSE '整体属于能满足普通家庭使用的水平，细节仍有提升空间。'
        END
      )
      WHEN '日用百货' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '日常使用很方便，价格不高，实物和图片基本一致。'
          WHEN 1 THEN '能用但包装比较简单，收到时有一点挤压痕迹。'
          WHEN 2 THEN '颜色和尺寸都合适，放家里使用不突兀。'
          WHEN 3 THEN '做工一般，有轻微瑕疵，不影响使用但影响心情。'
          WHEN 4 THEN '实用性不错，买来马上就用上了，家人也觉得方便。'
          WHEN 5 THEN '材质没有异味，手感正常，属于比较稳的日用品。'
          WHEN 6 THEN '细节一般但价格合适，对日常消耗品来说可以接受。'
          ELSE '和同类商品相比没有特别惊喜，但基础体验过关。'
        END
      )
      WHEN '休闲食品' THEN CONCAT(
        product_name,
        CASE MOD(rn, 8)
          WHEN 0 THEN '味道不错，甜咸度比较合适，办公室分享也很方便。'
          WHEN 1 THEN '口感正常，但包装压得有点碎，影响了开箱体验。'
          WHEN 2 THEN '日期比较新，独立包装方便携带，回购可能性比较高。'
          WHEN 3 THEN '味道和预期不太一样，家里人接受度一般。'
          WHEN 4 THEN '分量合适，下午茶或追剧吃都可以，不会太腻。'
          WHEN 5 THEN '包装密封性还行，但希望外箱保护再好一点。'
          WHEN 6 THEN '整体口味比较大众，适合囤一点当零食。'
          ELSE '能吃但没有特别惊艳，按真实体验给分。'
        END
      )
      ELSE CONCAT(product_name, '整体体验比较普通，按实际使用感受评价。')
    END,
    CASE
      WHEN MOD(rn, 13) IN (0, 1, 2) THEN '\n补充：使用几天后整体感受更明确，优点和小问题都比较明显。'
      WHEN MOD(rn, 13) IN (3, 4) THEN '\n补充：如果后续包装和质检能再加强，整体体验会好很多。'
      WHEN MOD(rn, 13) = 5 THEN '\n补充：这条评价主要给后面购买的人做参考，不同使用场景感受可能不一样。'
      WHEN MOD(rn, 13) = 6 THEN '\n补充：极端差评不是因为单个小瑕疵，而是商品实际体验和预期差距比较大。'
      ELSE ''
    END
  ) AS content,
  'PUBLISHED' AS status,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 21) DAY) AS reviewed_at,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 21) DAY) AS created_at,
  NOW() AS updated_at,
  0 AS deleted
FROM tmp_wanxiang_102_after_sale_orders;

SELECT COUNT(*) AS selected_after_sale_count
FROM tmp_wanxiang_102_after_sale_orders;

SELECT status, COUNT(*) AS count_value
FROM twenty_mall_after_sale
WHERE after_sale_no LIKE 'WXAS102%'
  AND deleted = 0
GROUP BY status
ORDER BY status;

SELECT COUNT(*) AS selected_review_count
FROM twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
WHERE o.order_no LIKE 'WX102%'
  AND review.deleted = 0;

SELECT product_score, service_score, COUNT(*) AS count_value
FROM twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
WHERE o.order_no LIKE 'WX102%'
  AND review.deleted = 0
GROUP BY product_score, service_score
ORDER BY product_score DESC, service_score DESC;
