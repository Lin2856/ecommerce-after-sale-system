# 平台管理员端

管理员端使用 Vue 3 + TypeScript + Element Plus 开发，默认端口 `5175`。

## 当前功能

- 系统概览：展示商家、订单、售后、评价、知识库、规则等真实统计数据。
- 外部平台：展示万象商城等平台接入状态和配置。
- 同步监控：展示订单、售后、评价等数据库同步概况。
- 用户管理：查看消费者一级账号及其绑定的万象商城二级账号。
- 商家管理：查看商家一级账号及其绑定店铺数量和二级商家账号。
- 评价分析：查看评价数据、风险等级、已删除评价和评价详情。
- 评价异议审核：审核商家提出的评价异议，并决定是否删除评价。
- 争议订单处理：处理消费者二次售后争议，查看双方举证并裁定退款金额。
- 规则配置：维护售后规则、触发条件和执行动作。
- 知识库：维护知识文章、常见问题和售后政策。
- AI 配置：查看 AI 服务状态，编辑 API Key，配置会直接作用于真实 AI 对话。

## 启动方式

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\frontend\admin-web"
npm install
npm run dev
```

访问：`http://localhost:5175`

## 依赖服务

- 后端：`http://localhost:8080`
- AI 服务：`http://localhost:9000`

如果 AI 服务未启动，API Key 保存和 AI 状态检查会失败。

## 安全说明

管理员端只负责展示和提交 API Key，真实密钥写入本地 `ai-service/.env`，该文件不会提交到 GitHub。
