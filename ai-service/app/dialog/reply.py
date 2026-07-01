from app.api.schemas import ContextReplyRequest, ReplyResponse
from app.intent.classifier import classify_intent
from app.llm_client import llm_client


def build_reply(request: ContextReplyRequest) -> ReplyResponse:
    intent = classify_intent(request.text)
    reply = llm_client.generate_after_sale_reply(
        text=request.text,
        intent=intent.intent,
        category=intent.category,
        order_status=request.order_status,
        after_sale_status=request.after_sale_status,
        user_tone=request.user_tone,
    )
    suggestions = ["转人工客服", "补充订单信息", "补充问题凭证"]
    if not reply:
        reply = "AI 服务暂不可用，建议为您转接人工客服继续处理。"
    return ReplyResponse(
        reply=reply,
        intent=intent.intent,
        confidence=intent.confidence,
        suggestions=suggestions,
    )
