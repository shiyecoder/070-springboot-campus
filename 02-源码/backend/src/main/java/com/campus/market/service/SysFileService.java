package com.campus.market.service;

import com.campus.market.entity.SysFile;
import com.campus.market.mapper.SysFileMapper;
import org.springframework.stereotype.Service;

@Service
public class SysFileService extends BaseService<SysFile> {
    public SysFileService(SysFileMapper mapper) {
        this.baseMapper = mapper;
    }
}
