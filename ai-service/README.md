# AI 服务

AI 服务使用 Python + FastAPI 开发，默认端口 `9000`。它为三端系统提供真实 AI 客服回复、知识库解析、评价分析、店铺评价总体分析、AI 配置管理和基础 NLP 能力。

## 当前能力

- 真实客服回复：消费者发送消息后，后端携带订单、商品、商家、售后状态、聊天历史和知识库上下文调用 `/api/ai/reply`。
- 订单上下文问答：AI 可读取后端传入的商品规格、价格、数量、订单状态等字段，回答“容量是多少”“是否支持退货”等问题。
- AI 不确定处理：当模型判断信息不足或超出可回答范围时，会返回转人工建议，由消费者端展示转人工按钮。
- 评价分析：对单条评价生成情感、分析摘要和处理建议。
- 店铺总体分析：对店铺未删除评价进行整体情感倾向、问题归纳和改进建议总结。
- 知识库解析：根据用户上传的文本内容识别问题、分类、答案和政策类型，供用户确认后写入知识库。
- API Key 管理：管理员端可查看打码 Key、更新 Key，保存后直接作用于真实 AI 对话。

## 接口列表

- `GET /health`：健康检查。
- `GET /api/ai/config`：读取当前 AI 配置。
- `PUT /api/ai/config`：更新 API Key 并立即生效。
- `POST /api/ai/intent`：意图识别。
- `POST /api/ai/sentiment`：情感分析。
- `POST /api/ai/topic`：主题归类。
- `POST /api/ai/ticket/classify`：工单分类。
- `POST /api/ai/reply`：结合订单上下文生成客服回复。
- `POST /api/ai/review-analysis`：生成单条评价分析。
- `POST /api/ai/store-review-analysis`：生成店铺评价总体分析。
- `POST /api/ai/knowledge/extract`：从文本内容中抽取知识库条目。

## 启动方式

```powershell
cd "D:\Software Engineering Training\ecommerce-after-sale-system\ai-service"
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 9000
```

或在项目根目录使用：

```powershell
.\scripts\dev-start.ps1 -SkipBackend -SkipFrontend
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

## 安全说明

- `ai-service/.env` 已被 `.gitignore` 忽略，真实 API Key 不会上传到 GitHub。
- 管理员端保存 API Key 依赖 AI 服务正在运行。
- 如果消费者端 AI 不回复，优先检查 `http://localhost:9000/health`、API Key、后端 `APP_AI_BASE_URL` 和后端日志。
