package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 用户实体，对应数据库表 sys_user。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("sys_user")
public class SysUser {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String username;
    private String password;
    private String realName;
    private String phone;
    private String avatar;
    private String email;
    private String deptName;
    private Integer creditScore;
    private Integer status;
    private String remark;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
