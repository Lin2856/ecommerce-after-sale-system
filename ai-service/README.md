# AI 服务

AI 服务使用 Python + FastAPI 开发，端口默认为 `9000`。它为三端系统提供真实 AI 客服回复、AI 配置管理、轻量意图识别、情感分析、主题归类、工单分类和评价分析能力。

## 当前能力

- 真实客服回复：消费者端在线客服发送消息后，后端会携带订单、商品、商家、售后状态等上下文调用 `/api/ai/reply`。
- 订单上下文问答：AI 能根据商品规格、价格、数量、订单状态等数据库字段回答问题，例如“水杯容量是多少”可读取 `480mL` 规格。
- 评价分析：商家端点击“AI 分析”后调用 `/api/ai/review-analysis`，生成情感、分析摘要和处理建议。
- API Key 管理：管理员端可通过 `/api/ai/config` 查看、打码展示和更新 API Key。
- 兜底逻辑：未配置 API Key 或大模型调用失败时，部分接口会返回可用的本地规则结果，客服回复会提示转人工。

## 接口列表

- `GET /health`：健康检查。
- `GET /api/ai/config`：读取当前 AI 配置。
- `PUT /api/ai/config`：更新 API Key 并立即生效。
- `POST /api/ai/intent`：意图识别。
- `POST /api/ai/sentiment`：情感分析。
- `POST /api/ai/topic`：主题归类。
- `POST /api/ai/ticket/classify`：工单分类。
- `POST /api/ai/reply`：结合订单上下文生成客服回复。
- `POST /api/ai/review-analysis`：生成评价情感、分析摘要和处理建议。

## 启动方式

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\ai-service"
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 9000
```

## 大模型配置

默认使用 DeepSeek 兼容接口。真实密钥放在 `ai-service/.env`，不要提交到仓库。

```env
MODEL_PROVIDER=deepseek
DEEPSEEK_API_KEY=你的 API Key
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-chat
MODEL_MAX_TOKENS=800
LLM_TIMEOUT=30
```

也可以切换 `MODEL_PROVIDER=qwen`、`glm` 或 `openai`，并配置对应的 API Key、Base URL 和模型名。

## 重要说明

- `ai-service/.env` 已被 `.gitignore` 忽略，真实 API Key 不会上传到 GitHub。
- 管理员端保存 API Key 依赖 AI 服务正在运行。
- 如果消费者端 AI 不回复，优先检查 `9000/health`、API Key 是否已配置、后端是否能访问 AI 服务。
