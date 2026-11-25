package com.campus.market.service;

import com.campus.market.entity.SysUser;
import com.campus.market.mapper.SysUserMapper;
import org.springframework.stereotype.Service;

@Service
public class SysUserService extends BaseService<SysUser> {
    public SysUserService(SysUserMapper mapper) {
        this.baseMapper = mapper;
    }
}
