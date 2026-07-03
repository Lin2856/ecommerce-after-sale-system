# 后端服务

后端使用 Java + Spring Boot 开发，包名为 `com.example.mall`，端口默认为 `8080`。后端负责三端统一 API、MySQL 数据读写、账号绑定关系、万象商城订单售后评价数据、聊天会话、AI 服务转发和管理员治理能力。

## 当前职责

- 一级账号登录与资料管理。
- 万象商城消费者/商家二级账号绑定、解绑和唯一绑定校验。
- 消费者端订单、商品详情、地址、售后申请、二次争议、评价提交。
- 商家端店铺绑定、售后审核、退货物流、仅退款处理、争议举证、客服会话、评价异议。
- 管理员端系统概览、同步监控、用户/商家绑定关系、评价治理、规则配置、知识库、争议订单处理。
- 聊天消息持久化，支持 AI 服务、转人工、结束人工服务和三分钟无回复自动回到 AI。
- 调用 AI 服务生成消费者客服回复和评价分析结果。

## 主要模块

- `auth`：认证相关能力。
- `platform`：万象商城、本地模拟平台和管理员接口。
- `customer`：消费者客服会话与演示会话存储。
- `ai`：调用 FastAPI AI 服务。
- `common`：通用响应、异常和基础工具。

## 启动方式

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\backend"
$env:DB_PASSWORD="你的 MySQL 密码"
mvn.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

检查：

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/twenty-mall/admin/overview
```

## 数据库

默认使用 MySQL，库名建议为 `ecommerce_after_sale`。首次运行前请执行：

```sql
SOURCE database/init.sql;
SOURCE database/seed.sql;
```

增量演示数据脚本位于 `database/patch_*.sql`。

## AI 服务依赖

后端调用 AI 服务默认地址为 `http://localhost:9000`。如果 AI 服务未启动：

- 消费者端真实 AI 回复会失败或进入兜底提示。
- 商家端评价详情的“AI 分析”会失败。
- 管理员端保存 API Key 会提示 AI 服务不可用。

启动 AI 服务：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\ai-service"
python -m uvicorn app.main:app --host 0.0.0.0 --port 9000
```
