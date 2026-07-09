# 融合电商平台售后系统

本项目面向多电商平台售后服务、在线客服、订单售后闭环、评价治理和平台管理场景，提供消费者端、商家端、平台管理员端、后端服务、MySQL 数据库和 AI 服务的一体化演示系统。

系统当前接入两个自建模拟电商平台：`万象商城` 和 `悦购集市`。平台账号、一级账号、绑定关系、商品、订单、售后、争议、评价、聊天、知识库、规则和操作日志均以 MySQL 为统一数据源，三端通过后端 API 读写同一套数据。

## 当前能力

- 消费者端：支持手机号+密码登录、一级账号资料、二级平台账号绑定/解绑、订单查看、商品详情、仅退款/退货退款/价保/换货售后申请、退货物流、二次售后争议、AI 客服、转人工、图文评价提交和个人中心。
- 商家端：支持商家一级账号手机号+密码登录、二级店铺绑定/解绑、客服身份确认、售后审核、仅退款/退货退款/价保/换货处理、争议举证、实时客服、服务动态、评价分析、评价异议、知识库、规则查看、统计分析和操作日志。
- 管理员端：支持管理员秘钥登录、系统概览、消费者管理、商家管理、账号封禁/解封、同步监控、评价治理、评价异议审核、24 小时争议订单处理、全额/部分退款金额裁定、规则配置、知识库、AI 配置和管理员操作日志。
- 后端服务：统一承载三端 API、MySQL 数据读写、账号绑定校验、聊天会话、AI 服务转发和平台治理逻辑。
- AI 服务：提供真实大模型客服回复、订单上下文问答、知识库文本解析、单条评价分析、一级账号整体/单个二级商家评价分析和 API Key 管理。

## 技术栈

- 消费者端：微信小程序原生框架
- 商家端：Vue 3、TypeScript、Element Plus
- 管理员端：Vue 3、TypeScript、Element Plus
- 后端：Java 17、Spring Boot、MyBatis-Plus、Spring WebSocket、MySQL、Redis
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
├─ scripts/                    # 本地启动、检查、停止脚本
├─ docker-compose.yml
└─ README.md
```

## 推荐本地启动

项目提供本地启动脚本，可同时启动 AI 服务、后端、商家端和管理员端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system"
.\scripts\dev-start.ps1 -DbPassword "你的 MySQL 密码"
.\scripts\dev-check.ps1
```

访问地址：

- 后端接口：`http://localhost:8080`
- AI 服务：`http://localhost:9000`
- 商家端：`http://localhost:5177`
- 管理员端：`http://localhost:5175`
- 消费者端：使用微信开发者工具打开 `frontend/consumer-miniapp`

## 手动启动

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

## 数据库

数据库使用 MySQL，建议库名为 `ecommerce_after_sale`。首次初始化通常执行：

```sql
SOURCE database/init.sql;
SOURCE database/seed.sql;
```

增量数据脚本位于 `database/patch_*.sql`，用于补充万象商城、悦购集市、多二级账号、商品多订单、售后争议、操作日志、知识库、规则和演示账号数据。

## 密钥安全

- AI API Key 存放在 `ai-service/.env`，该文件被 `.gitignore` 忽略。
- 微信 AppID/AppSecret 建议通过环境变量或 `scripts/dev-start.ps1` 参数传入，不要写入仓库。
- `.env.example` 只保留变量名示例，不包含真实密钥。
- `outputs/` 为本地导出目录，已忽略，不上传账号表格等临时文件。

## 当前边界

- 万象商城、悦购集市均为自建演示电商平台，不是真实外部开放平台。
- 当前登录方式以手机号+密码为准，验证码和第三方登录入口已从三端登录页移除。
- 短信验证码与第三方登录能力后续如需恢复，应接入真实服务商配置。
- 生产部署还需要补充 HTTPS、正式域名、密钥托管、权限审计、备份恢复、监控告警和公网回调地址。
