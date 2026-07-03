package com.example.mall.module.merchant.dto;

public record MerchantOperationLogResponse(
        Long id,
        String primaryAccount,
        String staffCode,
        String staffName,
        String actionType,
        String actionName,
        String targetType,
        String targetId,
        String detail,
        String createdAt
) {
}
