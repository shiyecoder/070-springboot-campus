package com.campus.market.service;

import com.campus.market.entity.SysMenu;
import com.campus.market.mapper.SysMenuMapper;
import org.springframework.stereotype.Service;

@Service
public class SysMenuService extends BaseService<SysMenu> {
    public SysMenuService(SysMenuMapper mapper) {
        this.baseMapper = mapper;
    }
}
