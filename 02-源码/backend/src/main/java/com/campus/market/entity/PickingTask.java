package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 备货任务实体，对应数据库表 picking_task。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("picking_task")
public class PickingTask {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String taskNo;
    private Long orderId;
    private String picker;
    private String shelfList;
    private Integer planQty;
    private Integer realQty;
    private LocalDateTime startTime;
    private LocalDateTime finishTime;
    private String status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
