package com.campus.market.service;

import com.campus.market.entity.SysOperLog;
import com.campus.market.mapper.SysOperLogMapper;
import org.springframework.stereotype.Service;

@Service
public class SysOperLogService extends BaseService<SysOperLog> {
    public SysOperLogService(SysOperLogMapper mapper) {
        this.baseMapper = mapper;
    }
}
