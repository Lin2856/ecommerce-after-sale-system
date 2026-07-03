package com.example.mall.module.merchant.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.mall.common.response.ApiResponse;
import com.example.mall.module.merchant.dto.MerchantOperationLogRequest;
import com.example.mall.module.merchant.dto.MerchantOperationLogResponse;
import com.example.mall.module.merchant.entity.MerchantOperationLog;
import com.example.mall.module.merchant.mapper.MerchantOperationLogMapper;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/merchant/operation-logs")
public class MerchantOperationLogController {

    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss");
    private final MerchantOperationLogMapper operationLogMapper;

    public MerchantOperationLogController(MerchantOperationLogMapper operationLogMapper) {
        this.operationLogMapper = operationLogMapper;
    }

    @GetMapping
    public ApiResponse<List<MerchantOperationLogResponse>> list(@RequestParam(required = false) String primaryAccount) {
        LambdaQueryWrapper<MerchantOperationLog> wrapper = new LambdaQueryWrapper<MerchantOperationLog>()
                .eq(primaryAccount != null && !primaryAccount.isBlank(), MerchantOperationLog::getPrimaryAccount, primaryAccount)
                .orderByDesc(MerchantOperationLog::getCreatedAt)
                .last("limit 200");
        List<MerchantOperationLogResponse> rows = operationLogMapper.selectList(wrapper).stream()
                .map(this::toResponse)
                .toList();
        return ApiResponse.success(rows, traceId());
    }

    @PostMapping
    public ApiResponse<MerchantOperationLogResponse> create(@Valid @RequestBody MerchantOperationLogRequest request) {
        MerchantOperationLog log = new MerchantOperationLog();
        log.setPrimaryAccount(request.primaryAccount());
        log.setStaffCode(request.staffCode());
        log.setStaffName(request.staffName());
        log.setActionType(request.actionType());
        log.setActionName(request.actionName());
        log.setTargetType(request.targetType());
        log.setTargetId(request.targetId());
        log.setDetail(request.detail());
        log.setCreatedAt(LocalDateTime.now());
        operationLogMapper.insert(log);
        return ApiResponse.success(toResponse(log), traceId());
    }

    private MerchantOperationLogResponse toResponse(MerchantOperationLog log) {
        return new MerchantOperationLogResponse(
                log.getId(),
                log.getPrimaryAccount(),
                log.getStaffCode(),
                log.getStaffName(),
                log.getActionType(),
                log.getActionName(),
                log.getTargetType(),
                log.getTargetId(),
                log.getDetail(),
                log.getCreatedAt() == null ? "" : log.getCreatedAt().format(FORMATTER)
        );
    }

    private String traceId() {
        return String.valueOf(System.currentTimeMillis());
    }
}
