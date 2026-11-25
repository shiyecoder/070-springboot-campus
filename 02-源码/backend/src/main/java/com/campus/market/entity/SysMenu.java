package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 菜单实体，对应数据库表 sys_menu。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_menu")
public class SysMenu {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long parentId;
    private String menuName;
    private String path;
    private String component;
    private String perms;
    private String icon;
    private String type;
    private Integer sortNo;
    private Integer visible;
    private Integer status;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
