# 部署说明

本目录记录本地联调和 Docker 部署相关说明。当前系统包含 MySQL、Redis、Spring Boot 后端、FastAPI AI 服务、商家端、管理员端和消费者微信小程序。

## 文件说明

- `../docker-compose.yml`：Docker Compose 编排入口。
- `../.env.example`：本地端口、数据库账号等环境变量示例。
- `nginx/spa.conf`：Web 前端静态资源、后端 `/api` 和 WebSocket `/ws` 的反向代理配置。
- `../backend/Dockerfile`：后端服务镜像构建。
- `../ai-service/Dockerfile`：AI 服务镜像构建。
- `../frontend/merchant-web/Dockerfile`：商家端镜像构建。
- `../frontend/admin-web/Dockerfile`：管理员端镜像构建。

## Docker 启动

在项目根目录执行：

```bash
copy .env.example .env
docker compose up -d --build
```

首次启动 MySQL 容器时会自动执行：

- `database/init.sql`
- `database/seed.sql`

如果已经生成过 MySQL 数据卷，修改 SQL 后不会自动重新初始化。需要重建演示数据库时执行：

```bash
docker compose down -v
docker compose up -d --build
```

这会删除容器卷中的数据库数据，只建议在开发或演示环境使用。

## 本机开发模式

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

消费者端使用微信开发者工具打开 `frontend/consumer-miniapp`。

## 访问地址

- 后端接口：`http://localhost:8080`
- AI 服务健康检查：`http://localhost:9000/health`
- 商家端：`http://localhost:5173`
- 管理员端：`http://localhost:5175`

## 常用命令

```bash
docker compose ps
docker compose logs -f backend
docker compose logs -f ai-service
docker compose restart backend
docker compose down
```

## 密钥说明

真实 AI API Key 存放在 `ai-service/.env`，该文件不会提交到 GitHub。管理员端 API Key 编辑功能会写入本地 AI 服务配置，保存前需要确保 AI 服务已启动。

## 生产环境补充事项

当前部署配置面向本地开发和演示。生产环境还需要补充：

- HTTPS 和正式域名。
- 统一密钥托管和权限审计。
- 数据库备份与恢复策略。
- 日志采集、监控和告警。
- 开放平台回调公网地址。
- 更严格的跨域、鉴权和访问控制。
