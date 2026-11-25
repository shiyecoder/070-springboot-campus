package com.campus.market.service;

import com.campus.market.entity.SysDictData;
import com.campus.market.mapper.SysDictDataMapper;
import org.springframework.stereotype.Service;

@Service
public class SysDictDataService extends BaseService<SysDictData> {
    public SysDictDataService(SysDictDataMapper mapper) {
        this.baseMapper = mapper;
    }
}
