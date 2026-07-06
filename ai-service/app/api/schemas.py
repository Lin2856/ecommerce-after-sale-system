from pydantic import BaseModel, ConfigDict, Field


def to_camel(value: str) -> str:
    parts = value.split("_")
    return parts[0] + "".join(part.capitalize() for part in parts[1:])


class ApiModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class TextRequest(ApiModel):
    text: str = Field(min_length=1)
    merchant_id: int | None = None
    business_type: str | None = None
    business_id: int | None = None


class ContextReplyRequest(TextRequest):
    order_status: str | None = None
    after_sale_status: str | None = None
    platform_name: str | None = None
    order_no: str | None = None
    merchant_name: str | None = None
    product_name: str | None = None
    product_sku: str | None = None
    product_description: str | None = None
    product_price: str | None = None
    product_quantity: str | None = None
    policy_tags: str | None = None
    user_tone: str | None = None


class AiConfigUpdateRequest(ApiModel):
    api_key: str = ""


class IntentResponse(ApiModel):
    intent: str
    category: str
    confidence: float
    summary: str


class SentimentResponse(ApiModel):
    sentiment: str
    score: float
    risk_level: str
    summary: str


class ReviewAnalysisRequest(ApiModel):
    platform_name: str | None = None
    order_no: str | None = None
    merchant_name: str | None = None
    product_name: str | None = None
    product_score: int | None = None
    service_score: int | None = None
    product_review: str | None = None
    merchant_review: str | None = None


class ReviewAnalysisResponse(ApiModel):
    sentiment: str
    analysis_summary: str
    suggestion: str


class StoreReviewItem(ApiModel):
    order_no: str | None = None
    merchant_name: str | None = None
    product_name: str | None = None
    product_score: int | None = None
    service_score: int | None = None
    product_review: str | None = None
    merchant_review: str | None = None
    risk_level: str | None = None


class StoreReviewAnalysisRequest(ApiModel):
    platform_name: str | None = None
    merchant_name: str | None = None
    reviews: list[StoreReviewItem] = Field(default_factory=list)


class StoreReviewAnalysisResponse(ApiModel):
    sentiment: str
    analysis_summary: str
    suggestion: str


class KnowledgeExtractRequest(ApiModel):
    text: str = Field(min_length=1)
    knowledge_type: str = "faq"


class KnowledgeExtractResponse(ApiModel):
    title: str
    category: str
    content: str


class TopicResponse(ApiModel):
    topics: list[str]
    keywords: list[str]
    summary: str


class TicketClassifyResponse(ApiModel):
    ticket_type: str
    priority: str
    category: str
    confidence: float
    due_hours: int


class ReplyResponse(ApiModel):
    reply: str
    intent: str
    confidence: float
    suggestions: list[str]
