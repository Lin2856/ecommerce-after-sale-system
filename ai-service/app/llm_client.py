from __future__ import annotations

import logging
import os
from typing import Any

from openai import OpenAI

from app.config import settings

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
        user_tone: str | None = None,
    ) -> str | None:
        if not self.is_configured():
            return None

        system_prompt = (
            "你是融合电商平台售后系统中的智能客服，只回答电商订单、退款、退货、售后政策、物流、评价等相关问题。"
            "回复必须使用中文，语气专业、礼貌、简洁。"
            "如果用户表达强烈不满、要求人工、问题超出能力范围，应建议转人工客服。"
            "不要编造具体退款金额、审核结论或平台已经完成的动作。"
        )
        context = (
            f"识别意图：{intent}\n"
            f"业务分类：{category}\n"
            f"订单状态：{order_status or '未知'}\n"
            f"售后状态：{after_sale_status or '未知'}\n"
            f"用户语气：{user_tone or '未知'}"
        )
        user_prompt = f"{context}\n\n用户问题：{text}\n\n请给出适合作为在线客服发送给消费者的一段回复。"

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

    def _api_key(self) -> str:
        return str(getattr(settings, f"{self.provider}_api_key", "") or "")

    def _base_url(self) -> str:
        return str(getattr(settings, f"{self.provider}_base_url", settings.deepseek_base_url))

    def _model_name(self) -> str:
        return str(getattr(settings, f"{self.provider}_model", settings.deepseek_model))


llm_client = LLMClient()
