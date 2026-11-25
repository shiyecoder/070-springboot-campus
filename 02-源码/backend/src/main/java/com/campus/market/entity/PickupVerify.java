package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 核销记录实体，对应数据库表 pickup_verify。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("pickup_verify")
public class PickupVerify {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String verifyNo;
    private Long orderId;
    private String pickupCode;
    private String verifier;
    private LocalDateTime verifyTime;
    private String verifyType;
    private String exceptionDesc;
    private Integer status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
