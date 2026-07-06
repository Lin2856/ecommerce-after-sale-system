package com.example.mall.module.ai.service;

import com.example.mall.module.ai.dto.AiReplyRequest;
import com.example.mall.module.ai.dto.AiTextRequest;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class AiCallLogService {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public AiCallLogService(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
        ensureTable();
    }

    public void record(String taskType, Object request, Object response, boolean success, String errorMessage, long latencyMs) {
        try {
            ensureTable();
            jdbcTemplate.update(
                """
                INSERT INTO ai_call_log (
                  merchant_id, user_id, business_type, business_id, task_type, model_version_id,
                  request_text, response_text, confidence, success, error_message, latency_ms
                ) VALUES (?, NULL, ?, ?, ?, NULL, ?, ?, NULL, ?, ?, ?)
                """,
                merchantId(request),
                businessType(request),
                businessId(request),
                taskType,
                requestText(request),
                toJson(response),
                success ? 1 : 0,
                trimError(errorMessage),
                Math.min(Math.max(latencyMs, 0), Integer.MAX_VALUE)
            );
        } catch (RuntimeException ignored) {
            // AI 调用日志不能影响真实 AI 回复流程。
        }
    }

    public void recordManual(
        Long merchantId,
        String businessType,
        Long businessId,
        String taskType,
        String requestText,
        String responseText,
        boolean success,
        String errorMessage,
        Integer latencyMs
    ) {
        try {
            ensureTable();
            jdbcTemplate.update(
                """
                INSERT INTO ai_call_log (
                  merchant_id, user_id, business_type, business_id, task_type, model_version_id,
                  request_text, response_text, confidence, success, error_message, latency_ms
                ) VALUES (?, NULL, ?, ?, ?, NULL, ?, ?, NULL, ?, ?, ?)
                """,
                merchantId,
                businessType == null || businessType.isBlank() ? "AI_SERVICE" : businessType,
                businessId,
                taskType == null || taskType.isBlank() ? "AI_CALL" : taskType,
                requestText,
                responseText,
                success ? 1 : 0,
                trimError(errorMessage),
                latencyMs == null ? null : Math.min(Math.max(latencyMs, 0), Integer.MAX_VALUE)
            );
        } catch (RuntimeException ignored) {
            // AI 调用日志不能影响页面上的真实 AI 功能。
        }
    }

    public long countAll() {
        ensureTable();
        Long value = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM ai_call_log", Long.class);
        return value == null ? 0 : value;
    }

    private void ensureTable() {
        jdbcTemplate.execute(
            """
            CREATE TABLE IF NOT EXISTS ai_call_log (
              id BIGINT PRIMARY KEY AUTO_INCREMENT,
              merchant_id BIGINT NULL,
              user_id BIGINT NULL,
              business_type VARCHAR(64) NOT NULL,
              business_id BIGINT NULL,
              task_type VARCHAR(64) NOT NULL,
              model_version_id BIGINT NULL,
              request_text TEXT NULL,
              response_text TEXT NULL,
              confidence DECIMAL(5,4) NULL,
              success TINYINT(1) NOT NULL DEFAULT 1,
              error_message VARCHAR(512) NULL,
              latency_ms INT NULL,
              created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
              KEY idx_ai_call_log_business (business_type, business_id),
              KEY idx_ai_call_log_merchant (merchant_id),
              KEY idx_ai_call_log_created_at (created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI调用日志'
            """
        );
    }

    private Long merchantId(Object request) {
        if (request instanceof AiTextRequest aiTextRequest) {
            return aiTextRequest.merchantId();
        }
        if (request instanceof AiReplyRequest aiReplyRequest) {
            return aiReplyRequest.merchantId();
        }
        return null;
    }

    private String businessType(Object request) {
        if (request instanceof AiTextRequest aiTextRequest && aiTextRequest.businessType() != null && !aiTextRequest.businessType().isBlank()) {
            return aiTextRequest.businessType();
        }
        if (request instanceof AiReplyRequest aiReplyRequest && aiReplyRequest.businessType() != null && !aiReplyRequest.businessType().isBlank()) {
            return aiReplyRequest.businessType();
        }
        return "AI_SERVICE";
    }

    private Long businessId(Object request) {
        if (request instanceof AiTextRequest aiTextRequest) {
            return aiTextRequest.businessId();
        }
        if (request instanceof AiReplyRequest aiReplyRequest) {
            return aiReplyRequest.businessId();
        }
        return null;
    }

    private String requestText(Object request) {
        if (request instanceof AiTextRequest aiTextRequest) {
            return aiTextRequest.text();
        }
        if (request instanceof AiReplyRequest aiReplyRequest) {
            return aiReplyRequest.text();
        }
        return toJson(request);
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ignored) {
            return String.valueOf(value);
        }
    }

    private String trimError(String errorMessage) {
        if (errorMessage == null || errorMessage.isBlank()) {
            return null;
        }
        return errorMessage.length() > 512 ? errorMessage.substring(0, 512) : errorMessage;
    }
}
