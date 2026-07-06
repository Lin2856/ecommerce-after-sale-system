# 数据库目录

本目录存放 MySQL 建表脚本、基础数据脚本、增量补丁脚本和 ER 说明。数据库建议使用 MySQL 8.0，库名建议为 `ecommerce_after_sale`。

## 核心文件

- `init.sql`：完整建表脚本，创建系统用户、平台、一级账号、二级平台账号、绑定关系、商品、订单、售后、争议、评价、客服、知识库、规则、AI 配置、操作日志等表。
- `seed.sql`：基础演示数据，包含万象商城、悦购集市入口、账号、商品、订单、售后、评价、知识库和规则等基础数据。
- `er.md`：数据库实体关系说明。
- `patch_*.sql`：增量补丁脚本，用于补充或迁移演示功能数据。

## 当前数据范围

- 平台：万象商城、悦购集市。
- 一级账号：消费者一级账号、商家一级账号、管理员秘钥账号。
- 二级账号：消费者平台账号、商家平台店铺账号。
- 业务数据：商品、订单、订单商品、售后申请、退货物流、二次争议、评价、聊天、知识库、规则、AI 配置。
- 审计数据：商家客服操作日志、管理员操作日志。

## 重要补丁脚本

- `patch_primary_account_bindings.sql`：一级账号与二级平台账号绑定关系。
- `patch_order_item_product_many_orders.sql`：支持一个商品对应多个订单。
- `patch_after_sale_dispute.sql`：二次售后争议订单。
- `patch_merchant_operation_log.sql`：商家客服身份确认与操作日志。
- `patch_merchant_accounts_and_consumer_nicknames.sql`：商家一级账号手机号化、消费者二级账号昵称优化。
- `patch_wanxiang_food_store_orders.sql`：万象商城食品店铺与订单演示数据。
- `patch_yuegou_market_platform_accounts.sql`：悦购集市平台账号入口与绑定基础数据。
- `patch_yuegou_market_seed_accounts_products_orders.sql`：悦购集市 50 个消费者账号、10 个商家账号、商品和多订单数据。
- `patch_bind_yuegou_merchants_to_13338907682.sql`：将悦购集市商家二级账号绑定到指定商家一级账号。
- `patch_wanxiang_102_picture_orders.sql`：基于 `D:\others\picture 0` 六组商品图片生成万象商城 50 个消费者二级账号、6 个商家二级账号、商品和多订单数据。
- `patch_wanxiang_102_200_after_sales.sql`：从万象商城 WX102 批次随机挑选 200 个订单生成售后和评价。
- `patch_cleanup_twenty_mall_review_product_content.sql`：清洗评价内容，避免“产品质量评价”中混入商家服务评价文案。
- `patch_merchant_staff_secret.sql`：将商家端客服秘钥改为数据库数据。
- `patch_twenty_mall_multi_account_utf8.sql`：万象商城多二级账号绑定和订单售后评价数据。
- `patch_twenty_mall_after_sale_status_mix.sql`：万象商城售后状态分布。
- `patch_return_shipping.sql`：退货快递单号和寄回时间字段。
- `patch_rename_twenty_mall_to_wanxiang.sql`：将早期“20商城”数据改名为“万象商城”。
- `patch_admin_rules_more_items.sql`、`patch_admin_knowledge_more_items.sql`：补充规则和知识库演示内容。

## 初始化方式

在项目根目录执行：

```bash
mysql -u root -p < database/init.sql
mysql -u root -p ecommerce_after_sale < database/seed.sql
```

或进入 MySQL 后执行：

```sql
SOURCE database/init.sql;
SOURCE database/seed.sql;
```

如需完整恢复当前演示状态，建议在 `init.sql` 和 `seed.sql` 后，再按功能需要执行对应 `patch_*.sql`。

## 注意事项

- `init.sql` 会重建表结构，可能清空已有演示数据。
- 补丁脚本多数使用条件建表、条件插入或 `ON DUPLICATE KEY UPDATE`，便于重复执行，但执行前仍建议备份数据库。
- 账号、订单、评价、售后、聊天等运行数据以 MySQL 为准，不再依赖前端本地演示数据。
- 真实 AI API Key 不存储在 SQL 中，位于本地 `ai-service/.env`。
- 微信 AppID/AppSecret、AI API Key 等敏感信息不应写入 SQL 或 README。
