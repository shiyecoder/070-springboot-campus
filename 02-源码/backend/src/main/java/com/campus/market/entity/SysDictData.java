package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 字典数据实体，对应数据库表 sys_dict_data。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_dict_data")
public class SysDictData {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String dictType;
    private String dictLabel;
    private String dictValue;
    private Integer sortNo;
    private Integer status;
    private String remark;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
