# 数据库目录

本目录存放 MySQL 建表脚本、基础数据脚本、增量补丁脚本和 ER 说明。数据库建议使用 MySQL 8.0，库名建议为 `ecommerce_after_sale`。

## 核心文件

- `init.sql`：完整建表脚本，会创建系统用户、商家、平台、万象商城账号、商品、订单、售后、争议、评价、客服、规则、知识库、AI 配置等表。
- `seed.sql`：基础演示数据，包含角色、用户、商家、万象商城基础账号、订单、售后、评价、知识库、规则和 AI 配置等。
- `er.md`：数据库实体关系说明。
- `README.md`：当前目录说明。

## 增量补丁脚本

- `patch_admin_knowledge_more_items.sql`：补充管理员端知识文章和常见问题。
- `patch_admin_rules_more_items.sql`：补充售后规则配置。
- `patch_after_sale_dispute.sql`：创建二次售后争议订单表。
- `patch_primary_account_bindings.sql`：创建一级账号和二级平台账号绑定关系表，并写入绑定数据。
- `patch_rename_twenty_mall_to_wanxiang.sql`：将系统内“20商城”批量改名为“万象商城”。
- `patch_return_shipping.sql`：为退货退款流程增加退货快递单号和寄回时间字段。
- `patch_twenty_mall_50_accounts.sql`：生成 50 个万象商城消费者账号及对应订单、售后数据。
- `patch_twenty_mall_after_sale_status_mix.sql`：调整售后单状态分布，覆盖待审核、处理中、已结束等状态。
- `patch_twenty_mall_consumer_22222222.sql`：创建消费者账号 `22222222` 及 5 个订单。
- `patch_twenty_mall_merchant_20230142.sql`：创建或补充万象商城商家账号 `20230142`。
- `patch_twenty_mall_multi_account_utf8.sql`：支持一个一级账号绑定多个万象商城二级账号，并补充多账号订单、售后、评价数据。
- `patch_twenty_mall_order_detail_fields.sql`：为订单增加到货时间和售后政策标签字段。
- `patch_twenty_mall_reviews.sql`：补充万象商城评价数据。
- `patch_twenty_mall_two_merchants.sql`：补充两个万象商城商家、商品和订单归属关系。

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

如需恢复完整演示数据，建议先执行 `init.sql`，再执行 `seed.sql`，最后按需要执行对应 `patch_*.sql`。

## 注意事项

- `init.sql` 会重建表结构，可能清空已有演示数据。
- 补丁脚本多数使用 `ON DUPLICATE KEY UPDATE` 或条件建表，便于重复执行，但仍建议执行前备份数据库。
- 真实 API Key 不存储在这些 SQL 脚本中，AI Key 位于本地 `ai-service/.env`。
