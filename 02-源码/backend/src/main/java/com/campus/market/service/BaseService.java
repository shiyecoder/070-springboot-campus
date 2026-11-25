package com.campus.market.service;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

/**
 * 通用服务基类：封装 MyBatis-Plus 的 CRUD 能力。
 * 业务校验写在各自子类中，控制器只负责参数与返回结构。
 */
public abstract class BaseService<T> extends ServiceImpl<BaseMapper<T>, T> {
}
