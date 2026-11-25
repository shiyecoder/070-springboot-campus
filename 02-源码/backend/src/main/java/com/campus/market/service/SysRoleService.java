package com.campus.market.service;

import com.campus.market.entity.SysRole;
import com.campus.market.mapper.SysRoleMapper;
import org.springframework.stereotype.Service;

@Service
public class SysRoleService extends BaseService<SysRole> {
    public SysRoleService(SysRoleMapper mapper) {
        this.baseMapper = mapper;
    }
}
