# 融合电商平台售后系统

本项目面向电商售后服务、在线客服、订单售后闭环和用户评价分析场景，建设一个包含消费者端、商家端、平台管理员端、后端服务、MySQL 数据库和 AI 服务的三端联动系统。

当前自建模拟电商平台命名为“万象商城”。系统通过本地数据库模拟真实电商平台的消费者账号、商家账号、商品、订单、售后、评价、聊天和平台治理数据，用于完整演示多平台绑定、数据同步、售后处理、客服沟通和评价治理流程。

## 当前进度

系统已经具备本地联调和演示运行能力：

- 消费者端：支持一级账号登录、万象商城账号绑定、订单查看、商品详情、售后申请、修改/取消售后、二次售后争议、在线客服、AI 客服、转人工、评价提交、头像昵称、地址管理和账号注销。
- 商家端：支持一级账号登录、万象商城商家账号绑定/解绑、售后审核、退货退款流程、仅退款处理、争议举证、实时客服、结束人工服务、服务动态、评价分析、评价异议、知识库、规则查看和统计分析。
- 管理员端：支持系统概览、用户绑定关系、商家绑定关系、同步监控、评价分析、评价异议审核、争议订单处理、退款金额裁定、规则配置、知识库管理和 AI 配置。
- 后端服务：使用 MySQL 统一存储三端账号、绑定关系、订单、售后、争议、评价、聊天、知识库、规则和 AI 配置相关数据。
- AI 服务：提供真实大模型客服回复、订单上下文问答、API Key 管理接口和评价分析接口；API Key 存放在本地 `.env`，不会提交到 GitHub。

## 技术栈

- 消费者端：微信小程序原生框架
- 商家端：Vue 3、TypeScript、Element Plus
- 管理员端：Vue 3、TypeScript、Element Plus
- 后端：Java、Spring Boot、MyBatis-Plus、Spring WebSocket、MySQL
- AI 服务：Python、FastAPI、OpenAI 兼容接口、DeepSeek 默认配置
- 部署：Docker、Docker Compose、Nginx

## 项目结构

```text
ecommerce-after-sale-system/
├─ ai-service/                 # FastAPI AI 服务
├─ backend/                    # Spring Boot 后端
├─ database/                   # MySQL 初始化与补丁脚本
├─ deploy/                     # 部署说明与 Nginx 配置
├─ frontend/
│  ├─ admin-web/               # 管理员端
│  ├─ consumer-miniapp/        # 消费者微信小程序
│  └─ merchant-web/            # 商家端
├─ docker-compose.yml
└─ README.md
```

## 本地启动

后端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\backend"
$env:DB_PASSWORD="你的 MySQL 密码"
mvn.cmd spring-boot:run "-Dspring-boot.run.profiles=dev"
```

AI 服务：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\ai-service"
python -m uvicorn app.main:app --host 0.0.0.0 --port 9000
```

商家端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\frontend\merchant-web"
npm run dev
```

管理员端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\frontend\admin-web"
npm run dev
```

访问地址：

- 后端接口：`http://localhost:8080`
- AI 服务：`http://localhost:9000`
- 商家端：`http://localhost:5173`
- 管理员端：`http://localhost:5175`

## 数据库

数据库使用 MySQL，建议库名为 `ecommerce_after_sale`。完整初始化通常执行：

```sql
SOURCE database/init.sql;
SOURCE database/seed.sql;
```

后续增量功能脚本位于 `database/patch_*.sql`，用于补充万象商城账号、订单、售后状态、争议订单、规则配置、知识库、评价等演示数据。

## AI 配置安全

真实 API Key 配置在 `ai-service/.env`，该文件被 `.gitignore` 忽略，不会上传到代码仓库。管理员端的 API Key 编辑功能会直接写入本地 AI 服务配置，用于真实消费者端 AI 回复。

示例：

```env
MODEL_PROVIDER=deepseek
DEEPSEEK_API_KEY=你的 API Key
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
```

## 当前边界

- 万象商城为本地数据库模拟平台，不是真实外部开放平台。
- 抖音、淘宝、拼多多、京东等平台入口目前保留为绑定展示或扩展预留。
- 当前部署配置面向本地开发和演示；生产环境还需要完善 HTTPS、密钥托管、权限审计、备份恢复、监控告警和公网回调地址。
