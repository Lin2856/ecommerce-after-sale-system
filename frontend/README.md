# 前端目录

本目录包含三个前端应用，分别对应消费者端、商家端和管理员端。三端通过后端 API 读写 MySQL 中的统一数据，不再以本地假数据作为业务来源。

## 应用说明

- `consumer-miniapp`：消费者微信小程序，提供手机号/微信登录、平台账号绑定、订单、商品、售后、争议、客服、评价和个人中心能力。
- `merchant-web`：商家端 Web 后台，提供店铺绑定、客服身份确认、售后处理、实时客服、服务动态、评价分析、知识库、规则查看、统计分析和操作日志。
- `admin-web`：平台管理员 Web 后台，提供管理员秘钥登录、系统概览、消费者管理、商家管理、封禁/解封、同步监控、评价治理、争议订单、知识库、规则配置、AI 配置和操作日志。

## 本地端口

- 商家端：`http://localhost:5173`
- 管理员端：`http://localhost:5175`
- 消费者端：使用微信开发者工具打开 `frontend/consumer-miniapp`

## 推荐启动

项目根目录执行：

```powershell
.\scripts\dev-start.ps1 -DbPassword "你的 MySQL 密码"
```

该脚本会尝试启动 AI 服务、后端、商家端和管理员端。

## 手动运行

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
- MySQL：存储账号、绑定关系、商品、订单、售后、评价、聊天、知识库、规则和日志

AI 客服回复、AI 评价分析、知识库智能解析和管理员端 API Key 配置依赖 AI 服务可用。
