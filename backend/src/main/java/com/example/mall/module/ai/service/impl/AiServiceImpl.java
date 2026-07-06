package com.example.mall.module.ai.service.impl;

import com.example.mall.module.ai.dto.AiReplyRequest;
import com.example.mall.module.ai.dto.AiTextRequest;
import com.example.mall.module.ai.dto.IntentResponse;
import com.example.mall.module.ai.dto.ReplyResponse;
import com.example.mall.module.ai.dto.SentimentResponse;
import com.example.mall.module.ai.dto.TicketClassifyResponse;
import com.example.mall.module.ai.dto.TopicResponse;
import com.example.mall.module.ai.service.AiCallLogService;
import com.example.mall.module.ai.service.AiService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Duration;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Service
public class AiServiceImpl implements AiService {

    private final WebClient aiWebClient;
    private final ObjectMapper objectMapper;
    private final AiCallLogService aiCallLogService;

    public AiServiceImpl(WebClient aiWebClient, ObjectMapper objectMapper, AiCallLogService aiCallLogService) {
        this.aiWebClient = aiWebClient;
        this.objectMapper = objectMapper;
        this.aiCallLogService = aiCallLogService;
    }

    @Override
    public IntentResponse detectIntent(AiTextRequest request) {
        return post("/api/ai/intent", "INTENT_RECOGNITION", request, IntentResponse.class);
    }

    @Override
    public SentimentResponse analyzeSentiment(AiTextRequest request) {
        return post("/api/ai/sentiment", "SENTIMENT_ANALYSIS", request, SentimentResponse.class);
    }

    @Override
    public TopicResponse extractTopic(AiTextRequest request) {
        return post("/api/ai/topic", "TOPIC_EXTRACTION", request, TopicResponse.class);
    }

    @Override
    public TicketClassifyResponse classifyTicket(AiTextRequest request) {
        return post("/api/ai/ticket/classify", "TICKET_CLASSIFICATION", request, TicketClassifyResponse.class);
    }

    @Override
    public ReplyResponse generateReply(AiReplyRequest request) {
        return post("/api/ai/reply", "CHAT_REPLY", request, ReplyResponse.class);
    }

    private <T> T post(String uri, String taskType, Object body, Class<T> responseType) {
        long start = System.nanoTime();
        try {
            JsonNode response = aiWebClient.post()
                .uri(uri)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(JsonNode.class)
                .block(Duration.ofSeconds(5));
            long latencyMs = Duration.ofNanos(System.nanoTime() - start).toMillis();
            if (response == null) {
                aiCallLogService.record(taskType, body, null, false, "AI服务未返回内容", latencyMs);
                return null;
            }
            JsonNode data = response.has("data") ? response.get("data") : response;
            T result = objectMapper.convertValue(data, responseType);
            aiCallLogService.record(taskType, body, result, true, null, latencyMs);
            return result;
        } catch (RuntimeException ex) {
            long latencyMs = Duration.ofNanos(System.nanoTime() - start).toMillis();
            aiCallLogService.record(taskType, body, null, false, ex.getMessage(), latencyMs);
            throw ex;
        }
    }
}
