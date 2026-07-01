INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '未发货仅退款自动通过', 'REFUND_POLICY',
       JSON_OBJECT('orderStatus','PAID','logisticsStatus','NOT_SHIPPED'),
       JSON_OBJECT('allowRefund',true,'needManualReview',false),
       '订单已支付但商家尚未发货时，用户申请仅退款可直接进入退款处理。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '未发货仅退款自动通过' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '已发货仅退款转人工审核', 'MANUAL_REVIEW',
       JSON_OBJECT('logisticsStatus','SHIPPED'),
       JSON_OBJECT('allowRefund',false,'needManualReview',true),
       '商品已发货但用户申请仅退款时，需要人工核对物流轨迹、签收状态和商家举证。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '已发货仅退款转人工审核' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '签收超七天退货需人工审核', 'MANUAL_REVIEW',
       JSON_OBJECT('days',15,'reasonType','NO_REASON'),
       JSON_OBJECT('allowReturn',false,'needManualReview',true),
       '超过七天无理由期限后发起退货退款，需要人工确认是否存在质量问题或特殊承诺。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '签收超七天退货需人工审核' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '价保十五天处理规则', 'PRICE_PROTECTION',
       JSON_OBJECT('days',15,'reasonType','PRICE_PROTECTION'),
       JSON_OBJECT('priceProtectDays',15,'allowRefund',true),
       '订单签收后十五天内出现同款商品降价时，可按价保规则核算差价退款。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '价保十五天处理规则' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '运费险理赔识别规则', 'FREIGHT_INSURANCE',
       JSON_OBJECT('reasonType','NO_REASON'),
       JSON_OBJECT('needManualReview',false,'allowReturn',true),
       '订单包含运费险且用户按要求寄回商品时，系统记录退货物流并触发运费险理赔判断。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '运费险理赔识别规则' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '特殊商品售后人工复核', 'MANUAL_REVIEW',
       JSON_OBJECT('productCategory','生鲜/定制/贴身用品'),
       JSON_OBJECT('needManualReview',true,'priority','HIGH'),
       '生鲜、定制、贴身用品等特殊商品不直接套用普通退货规则，需要平台或商家人工复核。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '特殊商品售后人工复核' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '拒收商品物流核验规则', 'RETURN_POLICY',
       JSON_OBJECT('logisticsStatus','REJECTED'),
       JSON_OBJECT('allowReturn',true,'needManualReview',true),
       '用户拒收商品后，需要核对物流拒收记录、包裹状态和商家责任后再继续退款流程。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '拒收商品物流核验规则' AND deleted = 0);

INSERT INTO after_sale_rule (merchant_id, rule_name, rule_type, conditions_json, action_json, content, enabled, created_by)
SELECT NULL, '平台介入争议优先处理', 'PRIORITY',
       JSON_OBJECT('reasonType','PLATFORM_INTERVENTION'),
       JSON_OBJECT('priority','HIGH','needManualReview',true),
       '消费者申请平台介入后，该售后单进入高优先级队列，由管理员根据双方举证进行裁定。', 1, 4
WHERE NOT EXISTS (SELECT 1 FROM after_sale_rule WHERE rule_name = '平台介入争议优先处理' AND deleted = 0);
