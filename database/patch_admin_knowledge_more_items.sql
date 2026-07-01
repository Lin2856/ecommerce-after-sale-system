USE ecommerce_after_sale;

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '仅退款场景处理规范',
       '用户申请仅退款时，客服需先核验订单状态、物流状态、商品是否签收以及用户提交的原因。未发货订单可优先引导仅退款；已发货订单需结合物流轨迹、商品状态和平台规则判断是否支持仅退款。若涉及商品质量问题，应要求用户补充照片、视频或检测说明作为处理依据。',
       'AFTER_SALE_POLICY', JSON_ARRAY('仅退款', '售后', '审核'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '仅退款场景处理规范' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '退货退款审核标准',
       '退货退款申请需要重点检查订单签收时间、商品是否影响二次销售、是否属于特殊商品、用户退货原因以及凭证完整性。符合七天无理由且商品完好的订单可进入退货流程；质量问题、错发漏发等商责场景应优先通过审核，并在备注中记录责任归因。',
       'AFTER_SALE_POLICY', JSON_ARRAY('退货退款', '审核标准', '售后'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '退货退款审核标准' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '质量问题凭证要求',
       '质量问题类售后需要用户提供能清晰说明问题的凭证，包括商品整体照片、问题部位特写、外包装照片、物流面单以及必要的视频说明。客服在审核时应判断凭证是否与订单商品一致，是否能证明问题发生在签收后合理时间内，并根据严重程度标记处理优先级。',
       'PRODUCT_POLICY', JSON_ARRAY('质量问题', '凭证', '图片上传'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '质量问题凭证要求' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '价保申请处理说明',
       '用户申请价格保护时，需要核对订单支付时间、商品当前价格、活动类型、价保有效期以及是否存在优惠券、满减、秒杀等特殊价格因素。符合价保条件的订单可按差价退还；不符合条件时需在处理说明中写明原因，避免用户重复提交。',
       'PLATFORM_POLICY', JSON_ARRAY('价保', '差价', '售后政策'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '价保申请处理说明' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '运费险理赔说明',
       '运费险通常用于补偿用户退货产生的物流费用。客服需提醒用户使用平台认可的退货方式并保留物流单号。若订单包含运费险，系统应在退货退款流程中展示对应标签；实际赔付金额以平台和保险服务规则为准。',
       'PLATFORM_POLICY', JSON_ARRAY('运费险', '退货物流', '理赔'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '运费险理赔说明' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '拒收商品售后处理流程',
       '用户拒收商品后，客服应核对物流轨迹是否显示拒收或退回，并关注包裹是否已退回商家仓库。商品确认退回后可进入退款处理；若物流信息异常，需要联系物流或平台核实，避免在商品未回仓前提前完成退款。',
       'AFTER_SALE_POLICY', JSON_ARRAY('拒收', '物流', '退款'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '拒收商品售后处理流程' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '平台介入处理规范',
       '当买卖双方对售后处理结果存在争议时，可进入平台介入流程。系统应汇总订单信息、聊天记录、售后凭证、商家审核意见和处理时间线，帮助管理员快速判断争议焦点。客服回复需保持客观，不得承诺超出平台规则的处理结果。',
       'SERVICE_SCRIPT', JSON_ARRAY('平台介入', '争议处理', '客服规范'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '平台介入处理规范' AND deleted = 0);

INSERT INTO knowledge_article (merchant_id, title, content, category, tags, status, created_by)
SELECT NULL, '转人工客服判断标准',
       'AI 客服无法准确识别用户诉求、用户明确要求人工处理、订单存在高风险投诉、售后多次失败或用户情绪明显负向时，应转入人工客服。转人工时需要携带订单编号、用户最近消息、售后状态和历史处理记录，减少用户重复描述问题。',
       'SERVICE_SCRIPT', JSON_ARRAY('AI客服', '转人工', '服务规范'), 'PUBLISHED', 4
WHERE NOT EXISTS (SELECT 1 FROM knowledge_article WHERE title = '转人工客服判断标准' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '我可以直接申请仅退款吗？',
       '可以，但系统会根据订单状态、物流状态和商品情况判断是否支持。未发货订单通常可以申请仅退款；已发货或已签收订单需要结合商品问题和平台规则审核。',
       'REFUND', 30, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '我可以直接申请仅退款吗？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '申请退货退款需要上传照片吗？',
       '如果是质量问题、错发漏发、破损等原因，建议上传商品照片、问题部位照片和外包装照片。凭证越完整，商家审核速度通常越快。',
       'AFTER_SALE', 28, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '申请退货退款需要上传照片吗？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '商家拒绝售后申请怎么办？',
       '你可以先查看商家拒绝原因，补充凭证后修改售后申请；如果仍无法协商一致，可以保留订单、聊天记录和凭证，后续申请平台介入处理。',
       'AFTER_SALE', 26, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '商家拒绝售后申请怎么办？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '退货物流单号填错了怎么办？',
       '如果退货物流单号填写错误，请尽快联系商家客服或在售后详情中修改退货信息。若包裹已经寄出，请保留正确物流凭证，避免影响退款进度。',
       'LOGISTICS', 22, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '退货物流单号填错了怎么办？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '运费险什么时候赔付？',
       '运费险一般会在退货退款流程完成后根据平台和保险规则自动核算，具体到账时间以平台或保险服务方结果为准。',
       'REFUND', 21, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '运费险什么时候赔付？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '商品降价后怎么申请价保？',
       '如果订单商品支持价格保护，你可以在订单详情或售后入口选择价保申请。系统会核对订单支付时间、当前价格和价保有效期，符合条件后按规则退还差价。',
       'AFTER_SALE', 20, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '商品降价后怎么申请价保？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '拒收商品后多久退款？',
       '拒收后需要等待物流退回并由商家确认收货。商家确认商品退回后会继续处理退款，具体时间取决于物流回传和平台退款流程。',
       'LOGISTICS', 18, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '拒收商品后多久退款？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '为什么我的售后申请还在待审核？',
       '待审核表示商家尚未完成处理。你可以查看申请时间和商家处理进度，如果长时间未处理，可联系商家客服或等待系统提醒商家处理。',
       'AFTER_SALE', 16, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '为什么我的售后申请还在待审核？' AND deleted = 0);

INSERT INTO faq_item (merchant_id, question, answer, category, priority, enabled, created_by)
SELECT NULL, '如何联系人工客服？',
       '在在线客服页面输入转人工、人工客服或说明需要人工处理，系统会根据当前订单和商家信息切换到对应商家的人工会话。',
       'ACCOUNT', 14, 1, 4
WHERE NOT EXISTS (SELECT 1 FROM faq_item WHERE question = '如何联系人工客服？' AND deleted = 0);

