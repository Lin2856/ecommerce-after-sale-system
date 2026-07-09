# 部署说明

本目录记录本地联调、Docker 部署和生产部署注意事项。当前系统包含 MySQL、Redis、Spring Boot 后端、FastAPI AI 服务、商家端、管理员端和消费者微信小程序。

## 文件说明

- `../docker-compose.yml`：Docker Compose 编排入口。
- `../.env.example`：端口、数据库、AI、微信等环境变量示例，不包含真实密钥。
- `nginx/spa.conf`：Web 前端静态资源、后端 `/api` 和 WebSocket `/ws` 的反向代理配置。
- `../backend/Dockerfile`：后端服务镜像构建。
- `../ai-service/Dockerfile`：AI 服务镜像构建。
- `../frontend/merchant-web/Dockerfile`：商家端镜像构建。
- `../frontend/admin-web/Dockerfile`：管理员端镜像构建。

## 本机开发模式

推荐在项目根目录执行：

```powershell
.\scripts\dev-start.ps1 -DbPassword "你的 MySQL 密码"
.\scripts\dev-check.ps1
```

访问地址：

- 后端接口：`http://localhost:8080`
- AI 服务健康检查：`http://localhost:9000/health`
- 商家端：`http://localhost:5177`
- 管理员端：`http://localhost:5175`
- 消费者端：微信开发者工具导入 `frontend/consumer-miniapp`

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

## 常用命令

```bash
docker compose ps
docker compose logs -f backend
docker compose logs -f ai-service
docker compose restart backend
docker compose down
```

本地脚本：

```powershell
.\scripts\dev-start.ps1
.\scripts\dev-check.ps1
.\scripts\dev-stop.ps1
```

## 密钥说明

- AI API Key 存放在 `ai-service/.env`，该文件不会提交到 GitHub。
- 微信小程序 AppID/AppSecret、AI API Key、短信服务密钥等敏感信息应通过环境变量或密钥管理传入，不写入仓库。
- 生产环境应使用云厂商密钥管理、环境变量或容器 Secret 管理敏感配置。

## 生产环境补充事项

当前部署配置面向本地开发和演示。生产环境还需要补充：

- HTTPS、正式域名和微信小程序合法域名配置。
- AI、微信、短信等第三方密钥托管。
- 数据库备份与恢复策略。
- 日志采集、监控和告警。
- 更严格的跨域、鉴权、访问控制和操作审计。
