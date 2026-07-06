from __future__ import annotations

import logging
import os
import json
from typing import Any

from openai import OpenAI

from app.api.schemas import (
    KnowledgeExtractRequest,
    KnowledgeExtractResponse,
    ReviewAnalysisRequest,
    ReviewAnalysisResponse,
    StoreReviewAnalysisRequest,
    StoreReviewAnalysisResponse,
)
from app.config import settings
from app.sentiment.analyzer import analyze_sentiment

logger = logging.getLogger(__name__)


class LLMClient:
    def __init__(self) -> None:
        self.reload()

    def reload(self) -> None:
        self.provider = settings.model_provider.lower()
        self.api_key = self._api_key()
        self.base_url = self._base_url()
        self.model_name = self._model_name()
        os.environ.pop("SSLKEYLOGFILE", None)
        self.client = OpenAI(api_key=self.api_key or "sk-placeholder", base_url=self.base_url)

    def is_configured(self) -> bool:
        return bool(self.api_key)

    def generate_after_sale_reply(
        self,
        text: str,
        intent: str,
        category: str,
        order_status: str | None = None,
        after_sale_status: str | None = None,
        platform_name: str | None = None,
        order_no: str | None = None,
        merchant_name: str | None = None,
        product_name: str | None = None,
        product_sku: str | None = None,
        product_description: str | None = None,
        product_price: str | None = None,
        product_quantity: str | None = None,
        policy_tags: str | None = None,
        user_tone: str | None = None,
    ) -> str | None:
        if not self.is_configured():
            return None

        system_prompt = (
            "你是融合电商平台售后系统中的智能客服，只回答电商订单、退款、退货、售后政策、物流、评价等相关问题。"
            "回复必须使用中文，语气专业、礼貌、简洁。"
            "你会收到订单和商品的结构化上下文，这些字段来自系统数据库，是可信数据。"
            "只回答用户当前问到的内容，不要主动复述订单号、商品规格、价格、数量、售后政策等未被询问的信息。"
            "如果用户只是打招呼，只需要简短问候并询问需要什么帮助。"
            "不要把平台名称写成固定值，必须使用上下文中的电商平台字段。"
            "当用户询问容量、颜色、规格、价格、数量、商家、订单状态等信息时，必须优先依据结构化上下文直接回答。"
            "当用户询问七天无理由、运费险、平台保障等售后政策时，必须优先依据售后政策标签直接回答。"
            "如果结构化上下文中已经包含答案，不要建议用户去查看商品详情页或包装标注。"
            "如果用户询问商家拒绝原因、人工审核依据、平台裁定结果、退款能否通过、投诉责任归属等无法从上下文直接确认的信息，必须明确说明当前无法直接判断，并建议转人工客服。"
            "如果用户表达强烈不满、要求人工、问题超出能力范围，应建议转人工客服。"
            "需要转人工时，回复中必须包含“可以点击下方转人工客服按钮”这句话，方便前端展示转人工按钮。"
            "不要编造具体退款金额、审核结论或平台已经完成的动作。"
        )
        context = (
            f"识别意图：{intent}\n"
            f"业务分类：{category}\n"
            f"电商平台：{platform_name or '未知'}\n"
            f"订单编号：{order_no or '未知'}\n"
            f"商家名称：{merchant_name or '未知'}\n"
            f"商品名称：{product_name or '未知'}\n"
            f"商品规格：{product_sku or '未知'}\n"
            f"商品描述：{product_description or '未知'}\n"
            f"商品单价：{product_price or '未知'}\n"
            f"购买数量：{product_quantity or '未知'}\n"
            f"售后政策标签：{policy_tags or '未知'}\n"
            f"订单状态：{order_status or '未知'}\n"
            f"售后状态：{after_sale_status or '未知'}\n"
            f"用户语气：{user_tone or '未知'}"
        )
        user_prompt = (
            f"{context}\n\n用户问题：{text}\n\n"
            "请给出适合作为在线客服发送给消费者的一段回复。"
            "如果用户问题能由商品规格或订单上下文回答，请只给出和问题直接相关的具体字段值。"
            "如果用户只是问候，不要展开订单信息。"
            "如果不能由上下文直接回答，请说明原因，并提示可以点击下方转人工客服按钮。"
        )

        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                max_tokens=settings.model_max_tokens,
                timeout=settings.llm_timeout,
            )
            if response and response.choices:
                return response.choices[0].message.content
        except Exception as exc:
            logger.warning("LLM reply generation failed: %s", exc)
        return None

    def analyze_review(self, request: ReviewAnalysisRequest) -> ReviewAnalysisResponse:
        fallback = self._fallback_review_analysis(request)
        if not self.is_configured():
            return fallback

        product_review = request.product_review or ""
        merchant_review = request.merchant_review or ""
        system_prompt = (
            "你是融合电商平台售后系统中的评价分析助手。"
            "请基于用户对商品质量和商家服务的评价，输出专业、克制、可执行的商家侧分析。"
            "只返回 JSON，不要输出 Markdown，不要添加额外解释。"
            "JSON 字段必须为 sentiment、analysis_summary、suggestion。"
            "sentiment 必须使用中文，可选：正向、中性、负向、混合。"
            "analysis_summary 用一句话概括评价反映的核心问题或优势。"
            "suggestion 用一句话给出商家后续处理建议。"
        )
        user_prompt = (
            f"平台：{request.platform_name or '未知'}\n"
            f"订单号：{request.order_no or '未知'}\n"
            f"商家：{request.merchant_name or '未知'}\n"
            f"商品：{request.product_name or '未知'}\n"
            f"产品质量星级：{request.product_score or '未知'}\n"
            f"商家服务星级：{request.service_score or '未知'}\n"
            f"产品质量评价：{product_review or '未填写'}\n"
            f"商家服务评价：{merchant_review or '未填写'}\n\n"
            "请生成评价情感、分析摘要和处理建议。"
        )
        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                max_tokens=min(settings.model_max_tokens, 500),
                timeout=settings.llm_timeout,
                response_format={"type": "json_object"},
            )
            if not response or not response.choices:
                return fallback
            content = response.choices[0].message.content or ""
            payload = json.loads(content)
            return ReviewAnalysisResponse(
                sentiment=str(payload.get("sentiment") or fallback.sentiment),
                analysis_summary=str(payload.get("analysis_summary") or fallback.analysis_summary),
                suggestion=str(payload.get("suggestion") or fallback.suggestion),
            )
        except Exception as exc:
            logger.warning("LLM review analysis failed: %s", exc)
            return fallback

    def extract_knowledge(self, request: KnowledgeExtractRequest) -> KnowledgeExtractResponse:
        fallback = self._fallback_knowledge_extract(request)
        if not self.is_configured():
            return fallback

        knowledge_type = "售后政策" if request.knowledge_type == "rules" else "常见问题解答"
        category_hint = (
            "分类必须从 RETURN_REFUND、REFUND_ONLY、QUALITY_RETURN、REPAIR、PRICE_PROTECTION、FREIGHT_INSURANCE、LOGISTICS、PLATFORM_INTERVENTION、SPECIAL_GOODS、CUSTOM 中选择。"
            if request.knowledge_type == "rules"
            else "分类必须从 AFTER_SALE、REFUND、RETURN、LOGISTICS、PRICE_PROTECTION、EXCHANGE、REPAIR、CUSTOMER_SERVICE、GENERAL 中选择。"
        )
        system_prompt = (
            "你是融合电商售后系统的知识库整理助手。"
            "请从用户提供的文本中抽取一条可直接入库的知识内容。"
            "只返回 JSON，不要输出 Markdown，不要添加额外解释。"
            "JSON 字段必须为 title、category、content。"
            "title 是用户会搜索或客服会查看的问题/政策名称，必须简短明确。"
            "content 是专业、完整、可执行的中文说明，避免口语化。"
            f"{category_hint}"
        )
        user_prompt = (
            f"知识类型：{knowledge_type}\n"
            f"原始材料：\n{request.text}\n\n"
            "请识别并整理为一条知识库内容。"
        )
        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                max_tokens=min(settings.model_max_tokens, 700),
                timeout=settings.llm_timeout,
                response_format={"type": "json_object"},
            )
            if not response or not response.choices:
                return fallback
            payload = json.loads(response.choices[0].message.content or "")
            return KnowledgeExtractResponse(
                title=str(payload.get("title") or fallback.title).strip(),
                category=str(payload.get("category") or fallback.category).strip(),
                content=str(payload.get("content") or fallback.content).strip(),
            )
        except Exception as exc:
            logger.warning("LLM knowledge extraction failed: %s", exc)
            return fallback

    def _fallback_knowledge_extract(self, request: KnowledgeExtractRequest) -> KnowledgeExtractResponse:
        text = request.text.strip()
        first_line = next((line.strip(" ：:，,。") for line in text.splitlines() if line.strip()), "")
        title = first_line[:36] or ("售后政策" if request.knowledge_type == "rules" else "常见问题")
        category = self._knowledge_category(text, request.knowledge_type)
        if request.knowledge_type == "rules":
            content = text if len(text) >= 20 else f"该政策适用于相关售后场景，客服需结合订单状态、商品属性和平台规则进行处理。{text}"
        else:
            content = text if len(text) >= 20 else f"用户咨询该问题时，客服需先核对订单状态和商品信息，再根据平台售后规则给出处理路径。{text}"
        return KnowledgeExtractResponse(title=title, category=category, content=content)

    def _knowledge_category(self, text: str, knowledge_type: str) -> str:
        rules_map = [
            ("运费险", "FREIGHT_INSURANCE"),
            ("价保", "PRICE_PROTECTION"),
            ("价格保护", "PRICE_PROTECTION"),
            ("维修", "REPAIR"),
            ("质量", "QUALITY_RETURN"),
            ("仅退款", "REFUND_ONLY"),
            ("退货退款", "RETURN_REFUND"),
            ("退货", "RETURN_REFUND"),
            ("物流", "LOGISTICS"),
            ("平台介入", "PLATFORM_INTERVENTION"),
            ("特殊商品", "SPECIAL_GOODS"),
        ]
        faq_map = [
            ("价保", "PRICE_PROTECTION"),
            ("价格保护", "PRICE_PROTECTION"),
            ("物流", "LOGISTICS"),
            ("换货", "EXCHANGE"),
            ("维修", "REPAIR"),
            ("退货", "RETURN"),
            ("退款", "REFUND"),
            ("客服", "CUSTOMER_SERVICE"),
            ("售后", "AFTER_SALE"),
        ]
        mapping = rules_map if knowledge_type == "rules" else faq_map
        for keyword, category in mapping:
            if keyword in text:
                return category
        return "CUSTOM" if knowledge_type == "rules" else "GENERAL"

    def analyze_store_reviews(self, request: StoreReviewAnalysisRequest) -> StoreReviewAnalysisResponse:
        fallback = self._fallback_store_review_analysis(request)
        if not self.is_configured():
            return fallback

        active_reviews = request.reviews[:80]
        review_lines = []
        for index, review in enumerate(active_reviews, start=1):
            review_lines.append(
                f"{index}. 订单：{review.order_no or '未知'}；"
                f"商家：{review.merchant_name or request.merchant_name or '未知'}；"
                f"商品：{review.product_name or '未知'}；"
                f"产品星级：{review.product_score or '未知'}；"
                f"服务星级：{review.service_score or '未知'}；"
                f"风险：{review.risk_level or '未知'}；"
                f"产品评价：{review.product_review or '未填写'}；"
                f"商家评价：{review.merchant_review or '未填写'}"
            )
        system_prompt = (
            "你是融合电商平台的店铺评价分析助手。"
            "请基于店铺所有未删除评价生成总体分析，输出专业、克制、可执行的商家侧结论。"
            "只返回 JSON，不要输出 Markdown，不要添加额外解释。"
            "JSON 字段必须为 sentiment、analysis_summary、suggestion。"
            "sentiment 必须使用中文完整短句，不要只写“混合”“正向”“负向”等单个词；"
            "例如：整体偏正向，但存在少量商品质量和客服响应风险。"
            "analysis_summary 用 4 到 6 句话概括店铺整体评价表现、主要优势、集中问题、涉及商品类型和风险来源。"
            "suggestion 用 4 到 6 句话给出商家后续处理建议，必须包含优先处理事项、客服跟进方式、商品或履约优化方向。"
            "不要泛泛而谈，必须结合评价明细中的商品、星级、评价内容和风险等级。"
        )
        user_prompt = (
            f"平台：{request.platform_name or '未知'}\n"
            f"店铺：{request.merchant_name or '当前绑定店铺'}\n"
            f"评价总数：{len(request.reviews)}\n"
            "未删除评价明细：\n"
            + "\n".join(review_lines)
            + "\n\n请生成店铺整体情感、评价摘要和处理建议。"
        )
        try:
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                max_tokens=min(settings.model_max_tokens, 800),
                timeout=settings.llm_timeout,
                response_format={"type": "json_object"},
            )
            if not response or not response.choices:
                return fallback
            payload = json.loads(response.choices[0].message.content or "")
            return StoreReviewAnalysisResponse(
                sentiment=str(payload.get("sentiment") or fallback.sentiment),
                analysis_summary=str(payload.get("analysis_summary") or fallback.analysis_summary),
                suggestion=str(payload.get("suggestion") or fallback.suggestion),
            )
        except Exception as exc:
            logger.warning("LLM store review analysis failed: %s", exc)
            return fallback

    def _fallback_store_review_analysis(self, request: StoreReviewAnalysisRequest) -> StoreReviewAnalysisResponse:
        reviews = request.reviews
        total = len(reviews)
        if total == 0:
            return StoreReviewAnalysisResponse(
                sentiment="中性",
                analysis_summary="当前店铺暂无可用于分析的未删除评价，暂不能形成稳定结论。",
                suggestion="建议先积累有效评价样本，再结合商品质量、客服响应和售后处理记录进行复盘。"
            )
        low_score = sum(1 for item in reviews if (item.product_score or 0) <= 2 or (item.service_score or 0) <= 2)
        high_score = sum(1 for item in reviews if (item.product_score or 0) >= 4 and (item.service_score or 0) >= 4)
        avg_product = sum(item.product_score or 0 for item in reviews) / total
        avg_service = sum(item.service_score or 0 for item in reviews) / total
        if low_score >= max(1, total * 0.3):
            sentiment = "整体偏负向，低星评价占比较高，商品质量或服务体验需要优先整改"
        elif high_score >= total * 0.6 and low_score == 0:
            sentiment = "整体偏正向，用户认可度较高，暂未出现明显集中风险"
        elif low_score > 0 and high_score > 0:
            sentiment = "整体评价正负并存，优势商品表现较好，但部分订单暴露出质量或服务风险"
        else:
            sentiment = "整体表现较平稳，评价情绪不极端，但仍需要持续观察体验波动"
        product_names = [item.product_name for item in reviews if item.product_name]
        sample_products = "、".join(product_names[:4]) if product_names else "当前商品"
        risk_reviews = [
            item for item in reviews
            if (item.product_score or 0) <= 2 or (item.service_score or 0) <= 2 or (item.risk_level or "") in {"高风险", "中风险", "HIGH", "MEDIUM"}
        ]
        positive_reviews = [
            item for item in reviews
            if (item.product_score or 0) >= 4 and (item.service_score or 0) >= 4
        ]
        summary = (
            f"本次共分析 {total} 条未删除评价，涉及{sample_products}等商品，产品质量平均 {avg_product:.1f} 星，商家服务平均 {avg_service:.1f} 星。"
            f"其中高分评价 {high_score} 条，说明店铺在部分商品体验、基础履约或客服服务上已经获得用户认可。"
            f"同时低分或风险评价 {max(low_score, len(risk_reviews))} 条，反映仍存在需要跟进的体验短板。"
            "从评价内容看，应重点关注用户反复提到的商品品质、包装完整性、物流交付、客服响应速度和问题处理态度。"
            "如果负面评价集中在少数商品或少数履约环节，建议将其作为专项复盘对象，避免同类问题继续扩大。"
        )
        suggestion = (
            "建议先筛选低星和中高风险评价，由客服在 24 小时内完成回访，确认用户不满来自商品本身、物流破损、包装问题还是沟通处理。"
            "对涉及质量或破损的订单，应同步检查同批次商品、仓储打包和发货流程，并保留处理记录，便于后续追踪。"
            "对客服响应慢、解释不清或补偿方案争议较大的评价，应统一售后话术和处理权限，减少用户重复沟通成本。"
            "对高分评价中的商品卖点和服务亮点，可以沉淀到商品详情页、客服知识库和运营素材中，强化店铺稳定优势。"
            "后续建议按周观察低分评价占比和重复关键词变化，如果同类问题持续出现，需要安排商品、仓配和客服联合复盘。"
        )
        return StoreReviewAnalysisResponse(sentiment=sentiment, analysis_summary=summary, suggestion=suggestion)

    def _fallback_review_analysis(self, request: ReviewAnalysisRequest) -> ReviewAnalysisResponse:
        text = f"{request.product_review or ''}\n{request.merchant_review or ''}".strip()
        product_score = request.product_score or 0
        service_score = request.service_score or 0
        sentiment = analyze_sentiment(text)
        if product_score <= 2 or service_score <= 2:
            label = "负向"
        elif product_score >= 4 and service_score >= 4 and sentiment.sentiment != "NEGATIVE":
            label = "正向"
        elif sentiment.sentiment == "NEGATIVE":
            label = "负向"
        elif sentiment.sentiment == "POSITIVE":
            label = "正向"
        else:
            label = "中性"

        if label == "负向":
            summary = "评价反映用户对商品质量或服务体验存在不满，需要尽快核实具体原因。"
            suggestion = "建议客服主动联系用户，结合订单和售后记录给出补偿、换货或解释方案。"
        elif label == "正向":
            summary = "评价整体偏正向，用户认可商品体验或商家服务表现。"
            suggestion = "建议沉淀为优质评价样本，并继续保持当前商品履约和客服响应标准。"
        else:
            summary = "评价情绪较平稳，暂未体现明显风险，但仍可用于服务体验复盘。"
            suggestion = "建议持续关注同类商品评价变化，如出现集中反馈再安排专项跟进。"
        return ReviewAnalysisResponse(sentiment=label, analysis_summary=summary, suggestion=suggestion)

    def _api_key(self) -> str:
        return str(getattr(settings, f"{self.provider}_api_key", "") or "")

    def _base_url(self) -> str:
        return str(getattr(settings, f"{self.provider}_base_url", settings.deepseek_base_url))

    def _model_name(self) -> str:
        return str(getattr(settings, f"{self.provider}_model", settings.deepseek_model))


llm_client = LLMClient()
