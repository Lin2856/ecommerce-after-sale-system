package com.example.mall.module.merchant.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDateTime;
import lombok.Data;

@Data
@TableName("merchant_operation_log")
public class MerchantOperationLog {

    @TableId(type = IdType.AUTO)
    private Long id;
    private String primaryAccount;
    private String staffCode;
    private String staffName;
    private String actionType;
    private String actionName;
    private String targetType;
    private String targetId;
    private String detail;
    private LocalDateTime createdAt;
}
