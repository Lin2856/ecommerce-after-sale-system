package com.example.mall.module.merchant.dto;

import jakarta.validation.constraints.NotBlank;

public record MerchantOperationLogRequest(
        @NotBlank String primaryAccount,
        @NotBlank String staffCode,
        @NotBlank String staffName,
        @NotBlank String actionType,
        @NotBlank String actionName,
        @NotBlank String targetType,
        String targetId,
        String detail
) {
}
