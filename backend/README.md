# 后端服务

后端使用 Java 17 + Spring Boot 开发，默认端口 `8080`。它是三端数据流转的核心，负责统一 API、MySQL 数据读写、账号认证、平台账号绑定、订单售后评价、聊天会话、管理员治理和 AI 服务转发。

## 当前职责

- 一级账号手机号+密码登录、资料更新和封禁校验。
- 万象商城、悦购集市消费者/商家二级账号绑定、解绑和唯一绑定校验。
- 消费者端商品、订单、售后、退货物流、二次争议、评价和客服会话接口。
- 商家端店铺绑定、售后审核、仅退款/退货退款、争议举证、评价异议、知识库和操作日志接口。
- 管理员端系统概览、消费者管理、商家管理、账号封禁/解封、评价治理、规则配置、知识库、争议订单处理和管理员操作日志接口。
- 聊天消息持久化，支持 AI 回复、AI 不确定时转人工、人工客服、结束人工服务和超时回到 AI。
- 调用 AI 服务生成客服回复、知识库解析、单条评价分析、一级账号整体评价分析和单个二级商家评价分析。

## 主要模块

- `platform`：万象商城、悦购集市、自建演示电商平台和管理员接口。
- `customer`：消费者客服会话和演示会话存储。
- `merchant`：商家端操作日志等商家侧能力。
- `ai`：调用 FastAPI AI 服务。
- `auth`、`security`：认证、放行规则和基础安全配置。
- `common`：通用响应、异常和基础工具。

## 启动方式

推荐使用项目根目录脚本：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system"
.\scripts\dev-start.ps1 -DbPassword "你的 MySQL 密码"
```

手动启动：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\backend"
$env:DB_PASSWORD="你的 MySQL 密码"
mvn.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

## 配置项

- `DB_URL`、`DB_USERNAME`、`DB_PASSWORD`：MySQL 连接。
- `REDIS_HOST`、`REDIS_PORT`：Redis 连接。
- `APP_AI_BASE_URL`：AI 服务地址，默认 `http://localhost:9000`。

## 检查方式

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/api/health
Invoke-WebRequest -UseBasicParsing http://localhost:8080/swagger-ui.html
```

## 数据库依赖

默认使用 MySQL，库名建议为 `ecommerce_after_sale`。首次运行前请执行：

```sql
SOURCE database/init.sql;
SOURCE database/seed.sql;
```

增量演示数据脚本位于 `database/patch_*.sql`。

## AI 服务依赖

后端调用 AI 服务默认地址为 `http://localhost:9000`。如果 AI 服务未启动：

- 消费者端真实 AI 回复会失败或进入兜底提示。
- 商家端评价详情、一级账号整体评价分析和单个二级商家评价分析会失败。
- 管理员端 AI 配置读取/保存会失败。
- AI 自动解析知识库文本或文件会失败。
