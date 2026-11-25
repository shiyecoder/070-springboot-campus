package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * 自提点实体，对应数据库表 pickup_point。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("pickup_point")
public class PickupPoint {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String pointNo;
    private String name;
    private String locationDesc;
    private LocalTime openTime;
    private LocalTime closeTime;
    private String contactName;
    private String contactPhone;
    private Integer serveLimit;
    private Integer status;
    private String image;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
