package com.campus.market.service;

import com.campus.market.entity.SysDictType;
import com.campus.market.mapper.SysDictTypeMapper;
import org.springframework.stereotype.Service;

@Service
public class SysDictTypeService extends BaseService<SysDictType> {
    public SysDictTypeService(SysDictTypeMapper mapper) {
        this.baseMapper = mapper;
    }
}
