package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单明细实体，对应数据库表 order_item。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("order_item")
public class OrderItem {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String itemNo;
    private Long orderId;
    private Long goodsId;
    private Integer qty;
    private BigDecimal price;
    private BigDecimal amount;
    private Integer outOfStock;
    private Long replaceGoodsId;
    private Integer status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
