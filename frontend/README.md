# 前端目录

本目录包含三个前端应用，分别对应消费者端、商家端和管理员端。

## 应用说明

- `consumer-miniapp`：消费者微信小程序，提供登录、绑定万象商城账号、订单、售后、客服、评价和个人中心能力。
- `merchant-web`：商家端 Web 后台，提供店铺绑定、售后处理、实时客服、评价分析、知识库、规则查看和统计分析能力。
- `admin-web`：平台管理员 Web 后台，提供系统概览、绑定关系、同步监控、评价治理、争议订单、知识库、规则配置和 AI 配置能力。

三端数据通过后端 API 和 MySQL 统一流转，账号、绑定关系、订单、售后、评价和聊天记录都应以数据库为准。

## 本地端口

- 商家端：`http://localhost:5173`
- 管理员端：`http://localhost:5175`
- 消费者端：使用微信开发者工具打开 `frontend/consumer-miniapp`

## 运行方式

商家端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\frontend\merchant-web"
npm install
npm run dev
```

管理员端：

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\frontend\admin-web"
npm install
npm run dev
```

消费者端：

```text
使用微信开发者工具导入 frontend/consumer-miniapp 目录。
后端需运行在 http://localhost:8080。
```

## 依赖服务

- 后端服务：`http://localhost:8080`
- AI 服务：`http://localhost:9000`
- MySQL：用于三端真实数据同步

AI 客服回复、AI 评价分析和管理员端 API Key 配置依赖 AI 服务可用。
