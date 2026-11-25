package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 文件实体，对应数据库表 sys_file。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_file")
public class SysFile {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String fileName;
    private String filePath;
    private Long fileSize;
    private String fileType;
    private String bizType;
    private Long bizId;
    private Long uploaderId;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
