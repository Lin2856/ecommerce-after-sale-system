USE ecommerce_after_sale;
SET NAMES utf8mb4;

DROP TEMPORARY TABLE IF EXISTS tmp_yuegou_half_orders;
CREATE TEMPORARY TABLE tmp_yuegou_half_orders AS
SELECT *
FROM (
  SELECT
    o.id AS order_id,
    o.order_no,
    o.consumer_account_id,
    o.merchant_account_id,
    o.total_amount,
    oi.id AS order_item_id,
    oi.product_id,
    oi.product_name,
    p.category,
    ROW_NUMBER() OVER (ORDER BY MD5(o.order_no)) AS rn,
    COUNT(*) OVER () AS total_count
  FROM twenty_mall_order o
  JOIN twenty_mall_account merchant
    ON merchant.id = o.merchant_account_id
   AND merchant.platform_code = 'YUEGOU_MARKET'
   AND merchant.account_role = 'MERCHANT'
   AND merchant.deleted = 0
  JOIN twenty_mall_order_item oi
    ON oi.order_id = o.id
   AND oi.deleted = 0
  JOIN twenty_mall_product p
    ON p.id = oi.product_id
   AND p.deleted = 0
  WHERE o.deleted = 0
) picked
WHERE picked.rn <= FLOOR(picked.total_count / 2);

DELETE review
FROM twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET';

DELETE after_sale
FROM twenty_mall_after_sale after_sale
JOIN twenty_mall_order o ON o.id = after_sale.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET';

UPDATE twenty_mall_order o
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
SET o.after_sale_status = 'NONE',
    o.updated_at = NOW()
WHERE o.deleted = 0;

UPDATE twenty_mall_order_item oi
JOIN twenty_mall_order o ON o.id = oi.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
SET oi.after_sale_status = 'NONE',
    oi.updated_at = NOW()
WHERE oi.deleted = 0;

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
  CONCAT('YGAS', SUBSTRING(order_no, 3), LPAD(MOD(rn, 1000), 3, '0')) AS after_sale_no,
  order_id,
  order_item_id,
  CASE
    WHEN MOD(rn, 6) IN (1, 3) THEN 'REFUND_ONLY'
    ELSE 'RETURN_REFUND'
  END AS after_sale_type,
  CASE
    WHEN category IN ('台灯', '耳机', '键盘', '鼠标') THEN 'PRODUCT_QUALITY'
    WHEN category IN ('床单', '水杯') THEN 'OTHER'
    WHEN category IN ('背包', '雨伞', '挂衣架') THEN 'WRONG_GOODS'
    ELSE 'OTHER'
  END AS reason_type,
  CASE category
    WHEN '台灯' THEN '台灯到手后灯罩有轻微压痕，低亮度档会偶尔闪烁，申请售后处理。'
    WHEN '床单' THEN '床单面料手感可以，但边角有一处跳线，担心清洗后继续脱线，申请售后。'
    WHEN '挂衣架' THEN '挂衣架安装后有些晃，配件孔位和说明不太一致，希望商家协助处理。'
    WHEN '椅子' THEN '椅子坐垫支撑感和详情描述有差距，久坐不太舒服，申请售后。'
    WHEN '水杯' THEN '水杯外观不错，但杯盖密封性一般，倒放会轻微渗水，申请售后。'
    WHEN '耳机' THEN '耳机连接稳定性一般，右耳偶尔断连，影响正常使用，申请售后。'
    WHEN '背包' THEN '背包容量够用，但肩带缝线处有明显线头，担心后续开线，申请售后。'
    WHEN '键盘' THEN '键盘整体手感不错，但空格键回弹声音异常，申请售后检测。'
    WHEN '雨伞' THEN '雨伞撑开顺畅，但伞面有一处小污点，申请商家处理。'
    WHEN '鼠标' THEN '鼠标握感可以，但滚轮有轻微异响，使用体验受影响，申请售后。'
    ELSE CONCAT(product_name, '收到后和预期略有差距，申请售后处理。')
  END AS description,
  CASE
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
      THEN DATE_SUB(NOW(), INTERVAL (MOD(rn, 6) + 1) DAY)
    ELSE NULL
  END AS return_shipped_at,
  CASE
    WHEN MOD(rn, 6) = 0 THEN DATE_SUB(NOW(), INTERVAL (MOD(rn, 12) + 1) HOUR)
    ELSE DATE_SUB(NOW(), INTERVAL (MOD(rn, 18) + 2) DAY)
  END AS created_at,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 3) DAY) AS updated_at,
  0 AS deleted
FROM tmp_yuegou_half_orders;

UPDATE twenty_mall_order o
JOIN twenty_mall_after_sale after_sale ON after_sale.order_id = o.id AND after_sale.deleted = 0
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
SET o.after_sale_status = after_sale.status,
    o.updated_at = NOW()
WHERE o.deleted = 0;

UPDATE twenty_mall_order_item oi
JOIN twenty_mall_after_sale after_sale ON after_sale.order_item_id = oi.id AND after_sale.deleted = 0
JOIN twenty_mall_order o ON o.id = oi.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
SET oi.after_sale_status = after_sale.status,
    oi.updated_at = NOW()
WHERE oi.deleted = 0;

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
    WHEN MOD(rn, 10) IN (0, 1, 2) THEN 5
    WHEN MOD(rn, 10) IN (3, 4, 5, 6) THEN 4
    WHEN MOD(rn, 10) IN (7, 8) THEN 3
    ELSE 2
  END AS product_score,
  CASE
    WHEN MOD(rn, 10) IN (0, 1, 3, 4) THEN 5
    WHEN MOD(rn, 10) IN (2, 5, 6) THEN 4
    WHEN MOD(rn, 10) IN (7, 8) THEN 3
    ELSE 2
  END AS service_score,
  CONCAT(
    '产品质量评价：',
    CASE category
      WHEN '台灯' THEN CONCAT(
        '这款', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '光线比较柔和，晚上开着不刺眼，放在桌面上使用很舒服。'
          WHEN 1 THEN '外观和详情图接近，整体质感可以，不过边角做工还能再细一点。'
          WHEN 2 THEN '亮度档位够日常使用，阅读和临时办公都能覆盖。'
          WHEN 3 THEN '底座放得比较稳，开关反应正常，长时间点亮发热不明显。'
          WHEN 4 THEN '灯臂或灯罩调节起来比较顺手，能照到需要的位置。'
          ELSE '造型挺适合家用，灯光偏舒适，追求特别强亮度的话可能不够。'
        END
      )
      WHEN '床单' THEN CONCAT(
        '这套', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '摸起来比较柔软，铺上后不容易滑动，睡觉时没有明显粗糙感。'
          WHEN 1 THEN '颜色和图片接近，洗过一次没有明显掉色，但边角有一处线头。'
          WHEN 2 THEN '尺寸匹配床垫，四角包得住，翻身时不会总是卷起来。'
          WHEN 3 THEN '面料透气性还可以，夏天开空调盖着也不闷，整体比较满意。'
          WHEN 4 THEN '图案挺耐看，手感偏薄，适合春夏用，冬天会觉得不够厚实。'
          ELSE '做工大体可以，走线比预期整齐，不过刚拆开时有一点布料味。'
        END
      )
      WHEN '挂衣架' THEN CONCAT(
        '这个', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '装起来不复杂，放在玄关挂外套和包比较方便，占地也不大。'
          WHEN 1 THEN '杆体颜色挺干净，轻衣服没问题，挂厚大衣时会有轻微晃动。'
          WHEN 2 THEN '配件数量齐全，说明图能看懂，底座稳定性比普通款好一些。'
          WHEN 3 THEN '高度适合卧室使用，帽子和围巾分层挂起来比较清楚。'
          WHEN 4 THEN '收纳能力不错，但个别接口拧紧后还有一点缝隙，细节一般。'
          ELSE '整体实用，适合出租屋或小户型，承重不要放太满会更稳。'
        END
      )
      WHEN '椅子' THEN CONCAT(
        '这把', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '坐垫支撑感不错，放在书房办公两三个小时没有明显塌陷。'
          WHEN 1 THEN '外观比预想简洁，靠背角度舒服，不过坐垫对我来说略偏硬。'
          WHEN 2 THEN '安装孔位基本对得上，一个人装也能完成，椅脚比较稳。'
          WHEN 3 THEN '面料触感还行，久坐不闷，适合日常学习和办公。'
          WHEN 4 THEN '颜色和桌子很搭，靠背支撑腰部还可以，包装保护也比较到位。'
          ELSE '整体能满足日常使用，但如果长时间办公，建议再配一个腰靠。'
        END
      )
      WHEN '水杯' THEN CONCAT(
        '这个', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '容量适合通勤，放包里不占地方，杯口喝水也比较顺。'
          WHEN 1 THEN '保温效果正常，早上装热水到中午还有温度，但杯盖密封一般。'
          WHEN 2 THEN '杯身握感不错，茶水分离结构方便，清洗也不算麻烦。'
          WHEN 3 THEN '外观简洁，放办公室挺合适，底部防滑效果比想象中好。'
          WHEN 4 THEN '重量比较轻，随身带着不累，杯盖开合手感还可以。'
          ELSE '容量和材质符合预期，只是刚拆开有点味道，洗过后基本没了。'
        END
      )
      WHEN '耳机' THEN CONCAT(
        '这款', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '通勤听歌够用，佩戴不压耳，地铁里降噪效果能感受到。'
          WHEN 1 THEN '连接速度快，打电话声音清楚，不过偶尔会有一侧短暂断连。'
          WHEN 2 THEN '低延迟模式玩游戏还可以，耳机盒体积小，放口袋方便。'
          WHEN 3 THEN '音质偏清亮，人声比较靠前，长时间佩戴没有明显胀痛。'
          WHEN 4 THEN '续航比预期好，午休和路上用一天基本够，触控稍微敏感。'
          ELSE '整体表现稳定，适合日常视频会议和听播客，低音不是特别重。'
        END
      )
      WHEN '背包' THEN CONCAT(
        '这个', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '电脑夹层厚实，通勤装电脑、雨伞和水杯都能放下。'
          WHEN 1 THEN '版型比较挺，背上不显臃肿，但肩带缝线处线头有点多。'
          WHEN 2 THEN '分区设计实用，小物件不用全堆在一起，找东西方便。'
          WHEN 3 THEN '面料有一定防泼水效果，小雨里走一段问题不大。'
          WHEN 4 THEN '容量比看图大，短途出差装一套换洗衣物也够用。'
          ELSE '背负感还可以，肩带不勒，拉链顺滑度比普通包好一些。'
        END
      )
      WHEN '键盘' THEN CONCAT(
        '这把', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '敲击声音清脆，办公打字手感不错，键帽触感也舒服。'
          WHEN 1 THEN '连接稳定，切换设备比较顺，但空格键声音比其他键大一点。'
          WHEN 2 THEN '灯效不刺眼，晚上用很有氛围，桌面搭配效果不错。'
          WHEN 3 THEN '轴体回弹干脆，长文输入不累，快捷键布局也顺手。'
          WHEN 4 THEN '包装保护到位，键盘没有磕碰，整体做工比预期好。'
          ELSE '适合办公和轻度游戏，手感扎实，只是大键调校还有提升空间。'
        END
      )
      WHEN '雨伞' THEN CONCAT(
        '这把', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '伞面大小够两个人临时遮一下，开合顺畅，收纳也方便。'
          WHEN 1 THEN '颜色耐看，伞骨比较轻，普通下雨天使用没问题。'
          WHEN 2 THEN '遮阳效果不错，中午出门能明显感觉少晒一点。'
          WHEN 3 THEN '手柄握着舒服，按钮不松垮，放包里重量可以接受。'
          WHEN 4 THEN '伞布有一处小污点，但不影响使用，整体做工还算稳。'
          ELSE '适合日常通勤，小风天气没问题，大风天还是要注意。'
        END
      )
      WHEN '鼠标' THEN CONCAT(
        '这个', product_name,
        CASE MOD(rn, 6)
          WHEN 0 THEN '握感贴手，长时间办公手腕压力小，点击反馈也清楚。'
          WHEN 1 THEN '静音效果不错，晚上用不会吵到人，滚轮稍微有点声音。'
          WHEN 2 THEN '蓝牙连接稳定，切换电脑很方便，移动也比较跟手。'
          WHEN 3 THEN '外观透明设计挺特别，放在桌面上搭配感很好。'
          WHEN 4 THEN '大手用起来比较舒服，按键位置自然，不需要刻意适应。'
          ELSE '日常办公完全够用，灵敏度调节方便，底部脚垫滑动顺。'
        END
      )
      ELSE CONCAT(product_name, '整体符合预期，日常使用没有明显问题。')
    END,
    '\n商家服务评价：',
    CASE
      WHEN MOD(rn, 5) = 0 THEN CONCAT('商家核实问题后处理比较干脆，', ELT(MOD(rn, 4) + 1, '当天就给出方案。', '退款进度说明得很清楚。', '客服没有反复推脱。', '整体售后体验比预期好。'))
      WHEN MOD(rn, 5) = 1 THEN CONCAT('商家回复速度还可以，', ELT(MOD(rn, 4) + 1, '但拒绝原因写得有点简单。', '如果能补充检测依据会更好。', '沟通语气正常但解释不够细。', '希望后续处理更主动一些。'))
      WHEN MOD(rn, 5) = 2 THEN CONCAT('商家已经受理售后，', ELT(MOD(rn, 4) + 1, '客服确认信息比较快。', '后续还在等待进一步处理。', '处理速度中规中矩。', '希望退款或换货节点再透明一些。'))
      WHEN MOD(rn, 5) = 3 THEN CONCAT('商家同意退货退款，', ELT(MOD(rn, 4) + 1, '寄回地址和注意事项说得比较清楚。', '客服提醒保留物流单号，流程比较规范。', '沟通过程没有太多来回拉扯。', '整体处理方式可以接受。'))
      ELSE CONCAT('商家已收到寄回物流信息，', ELT(MOD(rn, 4) + 1, '客服回复比较及时。', '验收进度还可以再主动同步。', '退款时间说明得比较明确。', '希望最后退款能尽快完成。'))
    END,
    ELT(MOD(rn, 12) + 1,
      '这次主要是放在卧室使用。',
      '这次买来放办公室使用。',
      '这单是给家里老人买的。',
      '实际用了几天后再来评价。',
      '包装到手没有明显破损。',
      '整体和详情页描述基本一致。',
      '如果后续耐用度好会考虑回购。',
      '细节还有改进空间，但不是完全不能接受。',
      '同价位里表现算比较稳。',
      '适合日常使用，不太适合特别高强度场景。',
      '收到后和客服沟通过一次。',
      '使用场景比较普通，评价按真实体验写。'
    ),
    ELT(MOD(CONV(SUBSTRING(MD5(order_no), 1, 6), 16, 10), 20) + 1,
      '我比较在意外观细节，所以拆开后看得比较仔细。',
      '家里原来的同类商品坏了，这次算是临时补一个。',
      '收到后先简单试用了一下，确认基础功能没问题。',
      '因为是日常高频使用的东西，所以对稳定性要求会高一点。',
      '这次主要看中它的尺寸和颜色，实物基本能搭上家里的风格。',
      '拆箱时包装还算完整，商品本身没有明显磕碰。',
      '实际体验和页面宣传大体一致，但细节感受还是要看个人需求。',
      '用了几次之后才来评价，整体印象比刚拆开时更准确。',
      '如果后续使用中不出问题，这个价位我觉得还算合理。',
      '这类商品我之前也买过，所以会更关注做工和耐用度。',
      '买之前看了很久评价，收到后和预期没有差太多。',
      '给家里日常使用足够，追求特别精致的话可能还要再比较。',
      '物流到得不算慢，真正影响体验的还是商品细节。',
      '客服沟通后我才决定保留这条评价，内容按实际情况写。',
      '使用中最明显的感受是功能够用，但仍有小地方可以优化。',
      '这次购买主要是为了替换旧款，所以会特别比较使用差异。',
      '实物颜色在自然光下更接近详情图，晚上看会稍微有色差。',
      '我对包装要求不高，主要还是看商品本身是否好用。',
      '整体属于能用且比较实用的水平，没有夸张宣传那么惊艳。',
      '家人也试用了一下，反馈和我的感受基本一致。'
    ),
    ELT(MOD(CONV(SUBSTRING(MD5(CONCAT(order_no, product_name)), 7, 6), 16, 10), 24) + 1,
      '所以这条评价更多是按日常使用感受来写。',
      '后面如果继续使用出现问题，我会再补充反馈。',
      '家里人看过实物后，也觉得和页面展示差别不大。',
      '我不是特别追求高端质感，主要看它是不是好用。',
      '对这个价位来说，整体表现属于能接受的范围。',
      '如果商家后续能把细节再做好一点，体验会更稳。',
      '这次购买没有让我特别惊喜，但也没有明显踩雷。',
      '实物到手后的第一感觉比只看图片更直观。',
      '我比较在意长期耐用性，所以后续还会继续观察。',
      '同类商品里它的实用性还可以，细节分会扣一点。',
      '这次评价主要想给后面购买的人做个参考。',
      '整体不是完美款，但满足普通家庭使用没问题。',
      '如果是送人，建议先确认外观细节是否符合预期。',
      '这类商品最重要的还是稳定和耐用，目前表现中规中矩。',
      '客服处理方式会影响整体印象，这次感受还算清楚。',
      '我会更看重后续售后是否能跟上，而不只是商品本身。',
      '实际使用后觉得优点和小问题都比较明显。',
      '对比之前买过的同类商品，这次体验算正常水平。',
      '如果能把包装和质检再加强一点，会更让人放心。',
      '这条评价是结合拆箱、试用和售后沟通后的感受。',
      '整体体验没有特别夸张，按真实使用情况给分。',
      '商品本身有可取之处，但细节还需要继续优化。',
      '目前看适合日常使用，不太适合特别挑剔的人。',
      '如果只是普通使用场景，它的表现基本够用。'
    )
  ) AS content,
  'PUBLISHED' AS status,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 14) DAY) AS reviewed_at,
  DATE_SUB(NOW(), INTERVAL MOD(rn, 14) DAY) AS created_at,
  NOW() AS updated_at,
  0 AS deleted
FROM tmp_yuegou_half_orders;

UPDATE twenty_mall_review review
JOIN tmp_yuegou_half_orders picked
  ON picked.order_id = review.order_id
 AND picked.product_id = review.product_id
SET review.content = CONCAT(
      review.content,
      '\n追加评价：',
      CASE picked.category
        WHEN '台灯' THEN '又用了几天之后，发现灯光本身比较舒服，但细节差异还是挺明显的。如果只是晚上看看书、临时办公，体验基本够用；如果长时间学习，对亮度均匀度和灯臂稳定性要求比较高，就会更在意这些小问题。'
        WHEN '床单' THEN '清洗一次后再看，面料柔软度还可以，贴身感没有变差，但走线和边角处理会影响整体印象。家用不算差，只是希望商家后续质检更细一点。'
        WHEN '挂衣架' THEN '实际挂了几件外套和包之后，承重还算够用，但如果挂得比较满，稳定性会下降。适合日常轻量收纳，不建议把它当成特别重载的衣架。'
        WHEN '椅子' THEN '坐了一段时间再评价，短时间使用没有问题，久坐以后坐垫和靠背的支撑差异会比较明显。对办公时间长的人来说，可能需要搭配靠垫。'
        WHEN '水杯' THEN '装热水和茶水都试过，容量比较适合出门或办公室使用。主要问题集中在杯盖和清洗细节，如果商家能把密封件做得更稳，体验会提升很多。'
        WHEN '耳机' THEN '通勤、电话和刷视频都试了一下，音质日常够用，佩戴也不算累。连接稳定性和触控灵敏度会影响体验，尤其是会议中偶尔断一下会比较尴尬。'
        WHEN '背包' THEN '背了几天之后，容量和分区确实方便，电脑、水杯、文件都能分开放。缺点是细节线头和肩带边缘处理一般，长期耐用性还需要再观察。'
        WHEN '键盘' THEN '连续打字几天后，键帽触感和回弹都还不错，办公效率没受影响。大键声音和一致性稍微扣分，如果对键盘声音特别敏感，建议谨慎一点。'
        WHEN '雨伞' THEN '下雨天和晴天都用过，普通通勤没有问题。伞面大小够用，但强风天气稳定性一般，比较适合作为日常备用伞。'
        WHEN '鼠标' THEN '连续办公使用后，握感和移动都比较顺，手腕压力不大。滚轮声音、按键手感这些细节会影响安静环境下的使用体验。'
        ELSE '又使用了一段时间，整体感受比刚收到时更明确，优点和小问题都比较明显。'
      END,
      ' 这次评价写得长一点，是因为从下单、收货、试用到联系售后都经历了一遍。商品本身不是完全不能用，但细节会影响真实体验，比如包装保护、做工稳定性、客服解释是否清楚，这些都会影响我最后的评分。给后面购买的人一个参考：如果只是普通日常使用，可以结合价格接受；如果对品质细节要求很高，建议下单前多问清楚材质、尺寸和售后处理方式。'
    ),
    review.updated_at = NOW()
WHERE picked.rn % 9 = 0
  AND review.deleted = 0;

UPDATE twenty_mall_review review
JOIN tmp_yuegou_half_orders picked
  ON picked.order_id = review.order_id
 AND picked.product_id = review.product_id
SET review.product_score = 1,
    review.service_score = CASE WHEN picked.rn % 2 = 0 THEN 1 ELSE 2 END,
    review.content = CONCAT(
      '产品质量评价：',
      CASE picked.category
        WHEN '台灯' THEN CONCAT('这款', picked.product_name, '体验很差，灯光忽明忽暗，底座也不稳，晚上使用时非常影响心情。')
        WHEN '床单' THEN CONCAT('这套', picked.product_name, '让我很失望，边角走线松散，洗了一次就明显变形，完全不像详情页说得那么好。')
        WHEN '挂衣架' THEN CONCAT('这个', picked.product_name, '稳定性太差，挂两件厚衣服就开始晃，接口也有松动感，使用起来很不放心。')
        WHEN '椅子' THEN CONCAT('这把', picked.product_name, '坐感非常一般，坐垫偏硬，靠背支撑也弱，坐久了腰很不舒服。')
        WHEN '水杯' THEN CONCAT('这个', picked.product_name, '密封性很差，放包里漏水，把包里的东西都弄湿了，这点真的不能接受。')
        WHEN '耳机' THEN CONCAT('这款', picked.product_name, '连接频繁断开，通话时对方一直说听不清，基本影响正常使用。')
        WHEN '背包' THEN CONCAT('这个', picked.product_name, '线头很多，拉链也不顺，刚用没多久肩带位置就有开线迹象，质量让我很失望。')
        WHEN '键盘' THEN CONCAT('这把', picked.product_name, '按键手感不一致，空格键松垮，连接还会偶尔失灵，完全影响办公。')
        WHEN '雨伞' THEN CONCAT('这把', picked.product_name, '伞骨太软，稍微有风就变形，伞面还有污点，质量明显不过关。')
        WHEN '鼠标' THEN CONCAT('这个', picked.product_name, '滚轮异响明显，指针还会飘，办公时反复误操作，体验很差。')
        ELSE CONCAT(picked.product_name, '实际体验很差，质量和描述不符。')
      END,
      '\n商家服务评价：',
      CASE picked.rn % 3
        WHEN 0 THEN '联系商家后一直让我继续拍照补充材料，来回沟通很多次也没有给出明确解决方案，售后体验很糟糕。'
        WHEN 1 THEN '客服回复很慢，解释也比较敷衍，只反复强调流程，没有认真解决问题。'
        ELSE '商家处理态度让我不满意，问题已经描述得很清楚了，但给出的方案没有实际帮助。'
      END,
      ' 这次购物体验非常不满意，后续不会再考虑这家店。'
    ),
    review.updated_at = NOW()
WHERE picked.rn % 37 = 0
  AND review.deleted = 0;

UPDATE twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
SET review.content = TRIM(
  REPLACE(
    REPLACE(
      CASE
        WHEN LOCATE(CONCAT(CHAR(10), '商家服务评价：'), review.content) > 0
             AND LOCATE(CONCAT(CHAR(10), '补充：'), review.content) > LOCATE(CONCAT(CHAR(10), '商家服务评价：'), review.content)
          THEN CONCAT(
            SUBSTRING_INDEX(review.content, CONCAT(CHAR(10), '商家服务评价：'), 1),
            CHAR(10),
            '补充：',
            SUBSTRING_INDEX(review.content, CONCAT(CHAR(10), '补充：'), -1)
          )
        WHEN LOCATE(CONCAT(CHAR(10), '商家服务评价：'), review.content) > 0
          THEN SUBSTRING_INDEX(review.content, CONCAT(CHAR(10), '商家服务评价：'), 1)
        WHEN LOCATE('商家服务评价：', review.content) > 0
          THEN SUBSTRING_INDEX(review.content, '商家服务评价：', 1)
        ELSE review.content
      END,
      '商品评价：',
      ''
    ),
    '产品质量评价：',
    ''
  )
),
review.updated_at = NOW()
WHERE review.deleted = 0
  AND (
    review.content LIKE '%商家服务评价：%'
    OR review.content LIKE '%商品评价：%'
    OR review.content LIKE '%产品质量评价：%'
  );

SELECT
  COUNT(*) AS selected_order_count
FROM tmp_yuegou_half_orders;

SELECT
  after_sale.status,
  COUNT(*) AS count_value
FROM twenty_mall_after_sale after_sale
JOIN twenty_mall_order o ON o.id = after_sale.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
WHERE after_sale.deleted = 0
GROUP BY after_sale.status
ORDER BY after_sale.status;

SELECT
  COUNT(*) AS yuegou_review_count
FROM twenty_mall_review review
JOIN twenty_mall_order o ON o.id = review.order_id
JOIN twenty_mall_account merchant
  ON merchant.id = o.merchant_account_id
 AND merchant.platform_code = 'YUEGOU_MARKET'
WHERE review.deleted = 0;
