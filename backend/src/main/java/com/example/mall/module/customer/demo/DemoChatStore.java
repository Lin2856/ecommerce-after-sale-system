package com.example.mall.module.customer.demo;

import com.example.mall.module.customer.demo.DemoChatController.DemoChatMessageRequest;
import com.example.mall.module.customer.demo.DemoChatController.DemoChatMessageResponse;
import com.example.mall.module.customer.demo.DemoChatController.DemoConversationResponse;
import com.example.mall.module.ai.dto.AiReplyRequest;
import com.example.mall.module.ai.dto.ReplyResponse;
import com.example.mall.module.ai.service.AiCallLogService;
import com.example.mall.module.ai.service.AiService;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class DemoChatStore {

    private static final DateTimeFormatter DATE_TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final JdbcTemplate jdbcTemplate;
    private final AiService aiService;
    private final AiCallLogService aiCallLogService;

    public DemoChatStore(JdbcTemplate jdbcTemplate, AiService aiService, AiCallLogService aiCallLogService) {
        this.jdbcTemplate = jdbcTemplate;
        this.aiService = aiService;
        this.aiCallLogService = aiCallLogService;
        ensureTwentyMallChatTables();
    }

    public List<DemoConversationResponse> listConversations(List<String> merchantAccounts) {
        List<Object> args = new ArrayList<>();
        String accountFilter = "";
        if (merchantAccounts != null && !merchantAccounts.isEmpty()) {
            accountFilter = " AND ma.account_no IN (" + "?,".repeat(merchantAccounts.size()).replaceAll(",$", "") + ")";
            args.addAll(merchantAccounts);
        }
        String sql = """
            SELECT c.id, c.conversation_no, o.order_no, o.order_status,
                   i.product_name, i.sku_name, i.unit_price, i.quantity, p.description AS product_description,
                   o.policy_tags,
                   ma.platform_code,
                   ca.account_no AS consumer_account_no,
                   cpa.account_no AS consumer_primary_account_no,
                   ma.account_no AS merchant_account_no,
                   mpa.account_no AS merchant_primary_account_no,
                   ma.display_name AS merchant_name,
                   COALESCE(a.status, o.after_sale_status, 'NONE') AS after_sale_status,
                   c.status, c.ai_intent, c.last_message, c.last_message_at
            FROM twenty_mall_conversation c
            JOIN twenty_mall_order o ON o.id = c.order_id
            JOIN twenty_mall_order_item i ON i.order_id = o.id AND i.deleted = 0
            LEFT JOIN twenty_mall_product p ON p.id = i.product_id AND p.deleted = 0
            JOIN twenty_mall_account ca ON ca.id = o.consumer_account_id
            JOIN twenty_mall_account ma ON ma.id = o.merchant_account_id
            LEFT JOIN platform_account_binding cb ON cb.secondary_account_no = ca.account_no
                AND cb.secondary_account_role = 'CONSUMER'
                AND cb.bind_status = 'BOUND'
                AND cb.deleted = 0
            LEFT JOIN primary_account cpa ON cpa.id = cb.primary_account_id
                AND cpa.account_type = 'CONSUMER'
                AND cpa.deleted = 0
            LEFT JOIN platform_account_binding mb ON mb.secondary_account_no = ma.account_no
                AND mb.secondary_account_role = 'MERCHANT'
                AND mb.bind_status = 'BOUND'
                AND mb.deleted = 0
            LEFT JOIN primary_account mpa ON mpa.id = mb.primary_account_id
                AND mpa.account_type = 'MERCHANT'
                AND mpa.deleted = 0
            LEFT JOIN (
                SELECT aa.*
                FROM twenty_mall_after_sale aa
                JOIN (
                    SELECT order_id, MAX(id) AS max_id
                    FROM twenty_mall_after_sale
                    WHERE deleted = 0
                    GROUP BY order_id
                ) latest ON latest.max_id = aa.id
            ) a ON a.order_id = o.id
            WHERE c.deleted = 0 AND o.deleted = 0
            """ + accountFilter + """
            ORDER BY COALESCE(c.last_message_at, c.updated_at, c.created_at) DESC, c.id DESC
            """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> toConversationResponse(new DemoConversation(
            rs.getLong("id"),
            rs.getString("conversation_no"),
            rs.getString("order_no"),
            orderStatusText(rs.getString("order_status")),
            platformName(rs.getString("platform_code")),
            rs.getString("product_name"),
            rs.getString("sku_name"),
            rs.getString("product_description"),
            rs.getBigDecimal("unit_price") == null ? null : rs.getBigDecimal("unit_price").toPlainString(),
            String.valueOf(rs.getInt("quantity")),
            parsePolicyTags(rs.getString("policy_tags")),
            rs.getString("consumer_account_no"),
            rs.getString("consumer_primary_account_no"),
            rs.getString("merchant_account_no"),
            rs.getString("merchant_primary_account_no"),
            rs.getString("merchant_name"),
            afterSaleStatusText(rs.getString("after_sale_status")),
            rs.getString("status"),
            rs.getString("ai_intent"),
            rs.getString("last_message"),
            toLocalDateTime(rs.getTimestamp("last_message_at"))
        )), args.toArray());
    }

    public DemoConversationResponse getConversation(String orderNo) {
        return toConversationResponse(requireConversation(orderNo));
    }

    public List<DemoChatMessageResponse> listMessages(String orderNo) {
        DemoConversation conversation = requireConversation(orderNo);
        String sql = """
            SELECT id, sender_type, content, created_at
            FROM twenty_mall_chat_message
            WHERE conversation_id = ? AND deleted = 0
            ORDER BY created_at ASC, id ASC
            """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> toMessageResponse(
            orderNo,
            new DemoMessage(
                String.valueOf(rs.getLong("id")),
                rs.getString("sender_type"),
                speaker(rs.getString("sender_type")),
                rs.getString("content"),
                toLocalDateTime(rs.getTimestamp("created_at"))
            )
        ), conversation.id());
    }

    public DemoChatMessageResponse addMessage(String orderNo, DemoChatMessageRequest request) {
        DemoConversation conversation = requireConversation(orderNo);
        String senderType = normalizeSender(request.senderType());
        DemoMessage message = insertMessage(conversation, senderType, request.content(), false);
        if ("CONSUMER".equals(senderType)) {
            DemoConversation latestConversation = loadConversationByOrderNo(conversation.orderNo());
            if ("AI_SERVING".equals(latestConversation.status()) || shouldResumeAiService(latestConversation)) {
                if ("AGENT_SERVING".equals(latestConversation.status())) {
                    resumeAiService(latestConversation);
                    latestConversation = loadConversationByOrderNo(conversation.orderNo());
                }
                DemoAiReply aiReply = buildAiReply(latestConversation, request.content());
                insertMessage(latestConversation, "AI", aiReply.content(), true);
                if (!aiReply.loggedByAiService()) {
                    recordDemoChatAiCall(latestConversation, request.content(), aiReply.content(), aiReply.success(), aiReply.errorMessage());
                }
            }
        }
        return toMessageResponse(conversation.orderNo(), message);
    }

    public DemoConversationResponse transferToStaff(String orderNo) {
        DemoConversation conversation = requireConversation(orderNo);
        jdbcTemplate.update(
            """
            UPDATE twenty_mall_conversation
            SET status = 'AGENT_SERVING', transferred_at = COALESCE(transferred_at, NOW()), updated_at = NOW()
            WHERE id = ? AND deleted = 0
            """,
            conversation.id()
        );
        insertMessage(loadConversationByOrderNo(conversation.orderNo()), "STAFF", "您好，人工客服已接入，请继续描述需要处理的问题。", false);
        return toConversationResponse(loadConversationByOrderNo(conversation.orderNo()));
    }

    public DemoConversationResponse endAgentService(String orderNo) {
        DemoConversation conversation = requireConversation(orderNo);
        return endAgentService(conversation);
    }

    public DemoConversationResponse endAgentServiceById(Long conversationId) {
        DemoConversation conversation = requireConversationById(conversationId);
        return endAgentService(conversation);
    }

    private DemoConversationResponse endAgentService(DemoConversation conversation) {
        resumeAiService(conversation);
        DemoConversation latestConversation = loadConversationByOrderNo(conversation.orderNo());
        insertMessage(latestConversation, "AI", "人工服务已结束，后续问题将由AI客服继续为您处理。", true);
        return toConversationResponse(loadConversationByOrderNo(conversation.orderNo()));
    }

    private DemoConversation requireConversation(String orderNo) {
        List<DemoConversation> rows = queryConversationByOrderNo(orderNo);
        if (!rows.isEmpty()) {
            return rows.get(0);
        }
        createTwentyMallConversation(orderNo);
        return loadConversationByOrderNo(orderNo);
    }

    private DemoConversation loadConversationByOrderNo(String orderNo) {
        List<DemoConversation> rows = queryConversationByOrderNo(orderNo);
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("Conversation not found: " + orderNo);
        }
        return rows.get(0);
    }

    private DemoConversation requireConversationById(Long conversationId) {
        List<DemoConversation> rows = queryConversationById(conversationId);
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("Conversation not found: " + conversationId);
        }
        return rows.get(0);
    }

    private List<DemoConversation> queryConversationByOrderNo(String orderNo) {
        String sql = """
            SELECT c.id, c.conversation_no, o.order_no, o.order_status,
                   i.product_name, i.sku_name, i.unit_price, i.quantity, p.description AS product_description,
                   o.policy_tags,
                   ma.platform_code,
                   ca.account_no AS consumer_account_no,
                   cpa.account_no AS consumer_primary_account_no,
                   ma.account_no AS merchant_account_no,
                   mpa.account_no AS merchant_primary_account_no,
                   ma.display_name AS merchant_name,
                   COALESCE(a.status, o.after_sale_status, 'NONE') AS after_sale_status,
                   c.status, c.ai_intent, c.last_message, c.last_message_at
            FROM twenty_mall_conversation c
            JOIN twenty_mall_order o ON o.id = c.order_id
            JOIN twenty_mall_order_item i ON i.order_id = o.id AND i.deleted = 0
            LEFT JOIN twenty_mall_product p ON p.id = i.product_id AND p.deleted = 0
            JOIN twenty_mall_account ca ON ca.id = o.consumer_account_id
            JOIN twenty_mall_account ma ON ma.id = o.merchant_account_id
            LEFT JOIN platform_account_binding cb ON cb.secondary_account_no = ca.account_no
                AND cb.secondary_account_role = 'CONSUMER'
                AND cb.bind_status = 'BOUND'
                AND cb.deleted = 0
            LEFT JOIN primary_account cpa ON cpa.id = cb.primary_account_id
                AND cpa.account_type = 'CONSUMER'
                AND cpa.deleted = 0
            LEFT JOIN platform_account_binding mb ON mb.secondary_account_no = ma.account_no
                AND mb.secondary_account_role = 'MERCHANT'
                AND mb.bind_status = 'BOUND'
                AND mb.deleted = 0
            LEFT JOIN primary_account mpa ON mpa.id = mb.primary_account_id
                AND mpa.account_type = 'MERCHANT'
                AND mpa.deleted = 0
            LEFT JOIN (
                SELECT aa.*
                FROM twenty_mall_after_sale aa
                JOIN (
                    SELECT order_id, MAX(id) AS max_id
                    FROM twenty_mall_after_sale
                    WHERE deleted = 0
                    GROUP BY order_id
                ) latest ON latest.max_id = aa.id
            ) a ON a.order_id = o.id
            WHERE o.order_no = ? AND c.deleted = 0 AND o.deleted = 0
            LIMIT 1
            """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new DemoConversation(
            rs.getLong("id"),
            rs.getString("conversation_no"),
            rs.getString("order_no"),
            orderStatusText(rs.getString("order_status")),
            platformName(rs.getString("platform_code")),
            rs.getString("product_name"),
            rs.getString("sku_name"),
            rs.getString("product_description"),
            rs.getBigDecimal("unit_price") == null ? null : rs.getBigDecimal("unit_price").toPlainString(),
            String.valueOf(rs.getInt("quantity")),
            parsePolicyTags(rs.getString("policy_tags")),
            rs.getString("consumer_account_no"),
            rs.getString("consumer_primary_account_no"),
            rs.getString("merchant_account_no"),
            rs.getString("merchant_primary_account_no"),
            rs.getString("merchant_name"),
            afterSaleStatusText(rs.getString("after_sale_status")),
            rs.getString("status"),
            rs.getString("ai_intent"),
            rs.getString("last_message"),
            toLocalDateTime(rs.getTimestamp("last_message_at"))
        ), orderNo);
    }

    private List<DemoConversation> queryConversationById(Long conversationId) {
        String sql = """
            SELECT c.id, c.conversation_no, o.order_no, o.order_status,
                   i.product_name, i.sku_name, i.unit_price, i.quantity, p.description AS product_description,
                   o.policy_tags,
                   ma.platform_code,
                   ca.account_no AS consumer_account_no,
                   cpa.account_no AS consumer_primary_account_no,
                   ma.account_no AS merchant_account_no,
                   mpa.account_no AS merchant_primary_account_no,
                   ma.display_name AS merchant_name,
                   COALESCE(a.status, o.after_sale_status, 'NONE') AS after_sale_status,
                   c.status, c.ai_intent, c.last_message, c.last_message_at
            FROM twenty_mall_conversation c
            JOIN twenty_mall_order o ON o.id = c.order_id
            JOIN twenty_mall_order_item i ON i.order_id = o.id AND i.deleted = 0
            LEFT JOIN twenty_mall_product p ON p.id = i.product_id AND p.deleted = 0
            JOIN twenty_mall_account ca ON ca.id = o.consumer_account_id
            JOIN twenty_mall_account ma ON ma.id = o.merchant_account_id
            LEFT JOIN platform_account_binding cb ON cb.secondary_account_no = ca.account_no
                AND cb.secondary_account_role = 'CONSUMER'
                AND cb.bind_status = 'BOUND'
                AND cb.deleted = 0
            LEFT JOIN primary_account cpa ON cpa.id = cb.primary_account_id
                AND cpa.account_type = 'CONSUMER'
                AND cpa.deleted = 0
            LEFT JOIN platform_account_binding mb ON mb.secondary_account_no = ma.account_no
                AND mb.secondary_account_role = 'MERCHANT'
                AND mb.bind_status = 'BOUND'
                AND mb.deleted = 0
            LEFT JOIN primary_account mpa ON mpa.id = mb.primary_account_id
                AND mpa.account_type = 'MERCHANT'
                AND mpa.deleted = 0
            LEFT JOIN (
                SELECT aa.*
                FROM twenty_mall_after_sale aa
                JOIN (
                    SELECT order_id, MAX(id) AS max_id
                    FROM twenty_mall_after_sale
                    WHERE deleted = 0
                    GROUP BY order_id
                ) latest ON latest.max_id = aa.id
            ) a ON a.order_id = o.id
            WHERE c.id = ? AND c.deleted = 0 AND o.deleted = 0
            LIMIT 1
            """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> new DemoConversation(
            rs.getLong("id"),
            rs.getString("conversation_no"),
            rs.getString("order_no"),
            orderStatusText(rs.getString("order_status")),
            platformName(rs.getString("platform_code")),
            rs.getString("product_name"),
            rs.getString("sku_name"),
            rs.getString("product_description"),
            rs.getBigDecimal("unit_price") == null ? null : rs.getBigDecimal("unit_price").toPlainString(),
            String.valueOf(rs.getInt("quantity")),
            parsePolicyTags(rs.getString("policy_tags")),
            rs.getString("consumer_account_no"),
            rs.getString("consumer_primary_account_no"),
            rs.getString("merchant_account_no"),
            rs.getString("merchant_primary_account_no"),
            rs.getString("merchant_name"),
            afterSaleStatusText(rs.getString("after_sale_status")),
            rs.getString("status"),
            rs.getString("ai_intent"),
            rs.getString("last_message"),
            toLocalDateTime(rs.getTimestamp("last_message_at"))
        ), conversationId);
    }

    private void createTwentyMallConversation(String orderNo) {
        String sql = """
            INSERT INTO twenty_mall_conversation (conversation_no, order_id, status, ai_intent, last_message, last_message_at)
            SELECT CONCAT('CV', o.order_no), o.id, 'AI_SERVING', '售后咨询',
                   CONCAT('会话已创建，请描述订单 ', o.order_no, ' 需要咨询的问题。'), NOW()
            FROM twenty_mall_order o
            WHERE o.order_no = ? AND o.deleted = 0
            ON DUPLICATE KEY UPDATE deleted = 0, updated_at = NOW()
            """;
        int affected = jdbcTemplate.update(sql, orderNo);
        if (affected == 0) {
            throw new IllegalArgumentException("Order not found: " + orderNo);
        }
        DemoConversation conversation = loadConversationByOrderNo(orderNo);
        Integer count = jdbcTemplate.queryForObject(
            "SELECT COUNT(1) FROM twenty_mall_chat_message WHERE conversation_id = ? AND deleted = 0",
            Integer.class,
            conversation.id()
        );
        if (count == null || count == 0) {
            insertMessage(conversation, "AI", "您好，我是AI客服，当前正在为你处理订单 " + orderNo + " 的咨询，请描述需要查询或处理的问题。", true);
        }
    }

    private DemoMessage insertMessage(DemoConversation conversation, String senderType, String content, boolean aiGenerated) {
        jdbcTemplate.update(
            """
            INSERT INTO twenty_mall_chat_message (conversation_id, sender_type, content, ai_generated)
            VALUES (?, ?, ?, ?)
            """,
            conversation.id(),
            senderType,
            content,
            aiGenerated ? 1 : 0
        );
        Long messageId = jdbcTemplate.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
        LocalDateTime createdAt = jdbcTemplate.queryForObject(
            "SELECT created_at FROM twenty_mall_chat_message WHERE id = ?",
            (rs, rowNum) -> toLocalDateTime(rs.getTimestamp("created_at")),
            messageId
        );
        jdbcTemplate.update(
            """
            UPDATE twenty_mall_conversation
            SET last_message = ?, last_message_at = ?, updated_at = NOW()
            WHERE id = ?
            """,
            content,
            Timestamp.valueOf(createdAt),
            conversation.id()
        );
        return new DemoMessage(String.valueOf(messageId), senderType, speaker(senderType), content, createdAt);
    }

    private boolean shouldResumeAiService(DemoConversation conversation) {
        if (!"AGENT_SERVING".equals(conversation.status())) {
            return false;
        }
        LocalDateTime latestStaffMessageAt = latestStaffMessageAt(conversation.id());
        LocalDateTime referenceTime = latestStaffMessageAt != null ? latestStaffMessageAt : conversation.lastMessageAt();
        return referenceTime == null || referenceTime.plusMinutes(3).isBefore(LocalDateTime.now());
    }

    private LocalDateTime latestStaffMessageAt(Long conversationId) {
        return jdbcTemplate.query(
            """
            SELECT created_at
            FROM twenty_mall_chat_message
            WHERE conversation_id = ? AND sender_type = 'STAFF' AND deleted = 0
            ORDER BY created_at DESC, id DESC
            LIMIT 1
            """,
            (rs, rowNum) -> toLocalDateTime(rs.getTimestamp("created_at")),
            conversationId
        ).stream().findFirst().orElse(null);
    }

    private void resumeAiService(DemoConversation conversation) {
        jdbcTemplate.update(
            """
            UPDATE twenty_mall_conversation
            SET status = 'AI_SERVING', updated_at = NOW()
            WHERE id = ? AND deleted = 0
            """,
            conversation.id()
        );
    }

    private DemoAiReply buildAiReply(DemoConversation conversation, String content) {
        String greetingReply = buildGreetingReply(conversation, content);
        if (greetingReply != null) {
            return new DemoAiReply(greetingReply, false, true, null);
        }
        String policyReply = buildPolicyReply(conversation, content);
        if (policyReply != null) {
            return new DemoAiReply(policyReply, false, true, null);
        }
        try {
            ReplyResponse response = aiService.generateReply(new AiReplyRequest(
                content,
                null,
                "TWENTY_MALL_ORDER",
                conversation.id(),
                conversation.orderStatus(),
                conversation.afterSaleStatus(),
                conversation.platformName(),
                conversation.orderNo(),
                conversation.merchantName(),
                conversation.productName(),
                conversation.productSku(),
                conversation.productDescription(),
                conversation.productPrice(),
                conversation.productQuantity(),
                String.join("、", conversation.policyTags()),
                null
            ));
            if (response != null && response.reply() != null && !response.reply().isBlank()) {
                return new DemoAiReply(response.reply(), true, true, null);
            }
        } catch (Exception ex) {
            // Keep the conversation usable and give the consumer a business-facing handoff message.
            return new DemoAiReply(fallbackAiReply(conversation, content), false, false, ex.getMessage());
        }
        return new DemoAiReply(fallbackAiReply(conversation, content), false, false, "AI服务未返回有效回复");
    }

    private void recordDemoChatAiCall(DemoConversation conversation, String requestText, String responseText, boolean success, String errorMessage) {
        aiCallLogService.recordManual(
            null,
            "DEMO_CHAT",
            conversation.id(),
            "CHAT_REPLY",
            requestText,
            responseText,
            success,
            errorMessage,
            null
        );
    }

    private String fallbackAiReply(DemoConversation conversation, String content) {
        String question = content == null ? "" : content;
        if (containsAny(question, "为什么", "拒绝", "不同意", "原因", "凭什么")) {
            return "当前系统中暂时没有足够信息确认商家不同意本次售后申请的具体原因，我不能直接替商家作出判断。建议转接人工客服，由客服结合商家审核记录和订单售后材料进一步核实。您可以点击下方转人工客服按钮。";
        }
        if (containsAny(question, "退款", "退钱", "赔偿", "平台介入", "投诉", "责任")) {
            return "这个问题需要结合订单记录、售后材料和商家处理说明进一步核实，我目前不能直接给出确定结论。建议转接人工客服继续处理，避免给出不准确的答复。您可以点击下方转人工客服按钮。";
        }
        return "这个问题目前需要人工进一步核实订单和售后记录，我不能直接给出确定结论。您可以点击下方转人工客服按钮，由人工客服继续协助处理。";
    }

    private String buildGreetingReply(DemoConversation conversation, String content) {
        String question = content == null ? "" : content.trim();
        if (question.matches("^(你好|您好|哈喽|hello|hi|在吗|在不在)[？?！!。,.，\\s]*$")) {
            return "您好，我是" + conversation.platformName() + "AI客服，请问有什么可以帮您？";
        }
        return null;
    }

    private String buildPolicyReply(DemoConversation conversation, String content) {
        if (!isNoReasonReturnQuestion(content)) {
            return null;
        }
        boolean supported = conversation.policyTags().stream().anyMatch(tag -> containsAny(tag, "7天无理由", "七天无理由"));
        if (supported) {
            return "您这笔订单支持七天无理由退货。订单售后政策中包含“7天无理由退货”，在商品未使用、配件齐全且不影响二次销售的情况下，可以在规则期限内发起售后申请。您可以在订单详情页点击“申请售后”提交申请。";
        }
        if (!conversation.policyTags().isEmpty()) {
            return "当前订单的售后政策标签为“" + String.join("、", conversation.policyTags()) + "”，其中没有标注“7天无理由退货”。如果您仍需要退货退款，可以根据商品质量、物流或商家承诺等情况发起售后，必要时转人工客服进一步核实。";
        }
        return null;
    }

    private boolean isNoReasonReturnQuestion(String content) {
        return containsAny(content, "七天无理由", "7天无理由", "七天退货", "无理由退", "无理由退款", "无理由退货");
    }

    private boolean containsAny(String content, String... keywords) {
        if (content == null || content.isBlank()) {
            return false;
        }
        for (String keyword : keywords) {
            if (keyword != null && !keyword.isBlank() && content.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private List<String> parsePolicyTags(String policyTagsJson) {
        if (policyTagsJson == null || policyTagsJson.isBlank()) {
            return List.of();
        }
        String content = policyTagsJson.trim();
        if (content.startsWith("[") && content.endsWith("]")) {
            content = content.substring(1, content.length() - 1);
        }
        if (content.isBlank()) {
            return List.of();
        }
        List<String> tags = new ArrayList<>();
        for (String rawTag : content.split(",")) {
            String tag = rawTag.trim().replace("\"", "").replace("'", "");
            if (!tag.isBlank()) {
                tags.add(tag);
            }
        }
        return tags;
    }

    private void ensureTwentyMallChatTables() {
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS twenty_mall_conversation (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                conversation_no VARCHAR(64) NOT NULL UNIQUE,
                order_id BIGINT NOT NULL UNIQUE,
                status VARCHAR(32) NOT NULL DEFAULT 'AI_SERVING',
                ai_intent VARCHAR(64) DEFAULT '售后咨询',
                last_message VARCHAR(512) DEFAULT NULL,
                last_message_at DATETIME DEFAULT NULL,
                transferred_at DATETIME DEFAULT NULL,
                closed_at DATETIME DEFAULT NULL,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                deleted TINYINT(1) NOT NULL DEFAULT 0,
                INDEX idx_twenty_mall_conversation_order (order_id),
                INDEX idx_twenty_mall_conversation_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='万象商城客服会话'
            """);
        jdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS twenty_mall_chat_message (
                id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                conversation_id BIGINT NOT NULL,
                sender_type VARCHAR(32) NOT NULL,
                message_type VARCHAR(32) NOT NULL DEFAULT 'TEXT',
                content TEXT,
                ai_generated TINYINT(1) NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                deleted TINYINT(1) NOT NULL DEFAULT 0,
                INDEX idx_twenty_mall_chat_message_conversation (conversation_id, created_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='万象商城聊天消息'
            """);
    }

    private String afterSaleStatusText(String status) {
        return switch (status == null ? "" : status) {
            case "PENDING_REVIEW" -> "待审核";
            case "PROCESSING" -> "处理中";
            case "REJECTED" -> "已拒绝";
            case "COMPLETED" -> "已完成";
            case "CLOSED" -> "已关闭";
            case "AFTER_SALE" -> "售后中";
            default -> "未申请";
        };
    }

    private String orderStatusText(String status) {
        return switch (status == null ? "" : status) {
            case "PENDING" -> "待处理";
            case "PAID" -> "已支付";
            case "UNPAID" -> "待支付";
            case "SHIPPED" -> "已发货";
            case "DELIVERED" -> "已送达";
            case "COMPLETED" -> "已完成";
            case "REFUNDED" -> "已退款";
            case "CANCELED" -> "已取消";
            case "CLOSED" -> "已关闭";
            default -> status == null || status.isBlank() ? "未知" : status;
        };
    }

    private DemoConversationResponse toConversationResponse(DemoConversation conversation) {
        return new DemoConversationResponse(
            conversation.id(),
            conversation.conversationNo(),
            conversation.orderNo(),
            cleanProductName(conversation.productName()),
            conversation.consumerAccountNo(),
            conversation.consumerPrimaryAccountNo(),
            conversation.merchantAccountNo(),
            conversation.merchantPrimaryAccountNo(),
            conversation.merchantName(),
            conversation.afterSaleStatus(),
            conversation.status(),
            conversation.aiIntent(),
            conversation.lastMessage(),
            formatTime(conversation.lastMessageAt())
        );
    }

    private DemoChatMessageResponse toMessageResponse(String orderNo, DemoMessage message) {
        return new DemoChatMessageResponse(message.id(), orderNo, message.senderType(), message.speaker(), message.content(), formatTime(message.createdAt()));
    }

    private String formatTime(LocalDateTime value) {
        return value == null ? "" : value.format(DATE_TIME_FORMATTER);
    }

    private LocalDateTime toLocalDateTime(Timestamp value) {
        return value == null ? null : value.toLocalDateTime();
    }

    private String cleanProductName(String productName) {
        if (productName == null) {
            return "";
        }
        return productName.replaceFirst("^万象商城\\s*", "").trim();
    }

    private String platformName(String platformCode) {
        return switch (platformCode == null ? "" : platformCode) {
            case "YUEGOU_MARKET" -> "悦购集市";
            case "TWENTY_MALL" -> "万象商城";
            default -> "商城平台";
        };
    }

    private String normalizeSender(String senderType) {
        String normalized = senderType.toUpperCase(Locale.ROOT);
        if ("USER".equals(normalized)) {
            return "CONSUMER";
        }
        if ("AGENT".equals(normalized) || "CUSTOMER_SERVICE".equals(normalized)) {
            return "STAFF";
        }
        return normalized;
    }

    private String speaker(String senderType) {
        return switch (senderType) {
            case "CONSUMER" -> "我";
            case "STAFF" -> "人工客服";
            case "AI" -> "AI客服";
            default -> "系统";
        };
    }

    private record DemoConversation(
        Long id,
        String conversationNo,
        String orderNo,
        String orderStatus,
        String platformName,
        String productName,
        String productSku,
        String productDescription,
        String productPrice,
        String productQuantity,
        List<String> policyTags,
        String consumerAccountNo,
        String consumerPrimaryAccountNo,
        String merchantAccountNo,
        String merchantPrimaryAccountNo,
        String merchantName,
        String afterSaleStatus,
        String status,
        String aiIntent,
        String lastMessage,
        LocalDateTime lastMessageAt
    ) {
    }

    private record DemoMessage(String id, String senderType, String speaker, String content, LocalDateTime createdAt) {
    }

    private record DemoAiReply(String content, boolean loggedByAiService, boolean success, String errorMessage) {
    }
}
