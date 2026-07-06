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
        platform_name=request.platform_name,
        order_no=request.order_no,
        merchant_name=request.merchant_name,
        product_name=request.product_name,
        product_sku=request.product_sku,
        product_description=request.product_description,
        product_price=request.product_price,
        product_quantity=request.product_quantity,
        policy_tags=request.policy_tags,
        user_tone=request.user_tone,
    )
    suggestions = ["转人工客服", "补充订单信息", "补充问题凭证"]
    if not reply:
        if any(keyword in request.text for keyword in ["为什么", "拒绝", "不同意", "原因", "凭什么"]):
            reply = "当前系统中暂时没有足够信息确认商家不同意本次售后申请的具体原因，我不能直接替商家作出判断。建议转接人工客服，由客服结合商家审核记录和订单售后材料进一步核实。您可以点击下方转人工客服按钮。"
        else:
            reply = "这个问题目前需要人工进一步核实订单和售后记录，我不能直接给出确定结论。您可以点击下方转人工客服按钮，由人工客服继续协助处理。"
    return ReplyResponse(
        reply=reply,
        intent=intent.intent,
        confidence=intent.confidence,
        suggestions=suggestions,
    )
