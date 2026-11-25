package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 缺货替换实体，对应数据库表 shortage_replace。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("shortage_replace")
public class ShortageReplace {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String replaceNo;
    private Long orderId;
    private Long originGoodsId;
    private Long replaceGoodsId;
    private Integer qty;
    private BigDecimal diffAmount;
    private Integer confirmFlag;
    private LocalDateTime confirmTime;
    private String status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
