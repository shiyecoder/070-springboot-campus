package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 站内消息实体，对应数据库表 sys_message。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_message")
public class SysMessage {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long receiverId;
    private String title;
    private String content;
    private String bizType;
    private Long bizId;
    private Integer readFlag;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
