package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * 自提时段实体，对应数据库表 pick_slot。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("pick_slot")
public class PickSlot {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String slotNo;
    private Long pointId;
    private LocalDate slotDate;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer capacity;
    private Integer bookedCount;
    private Integer status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
