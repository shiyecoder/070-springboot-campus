package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 公告实体，对应数据库表 sys_notice。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_notice")
public class SysNotice {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String title;
    private String content;
    private LocalDateTime publishTime;
    private Integer status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
