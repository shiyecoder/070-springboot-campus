package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 自提订单实体，对应数据库表 pickup_order。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("pickup_order")
public class PickupOrder {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String orderNo;
    private Long studentId;
    private Long pointId;
    private Long slotId;
    private BigDecimal goodsAmount;
    private BigDecimal payAmount;
    private String pickupCode;
    private LocalDateTime orderTime;
    private LocalDateTime readyTime;
    private String cancelReason;
    private String status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
