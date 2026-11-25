package com.campus.market.service;

import com.campus.market.entity.SysMessage;
import com.campus.market.mapper.SysMessageMapper;
import org.springframework.stereotype.Service;

@Service
public class SysMessageService extends BaseService<SysMessage> {
    public SysMessageService(SysMessageMapper mapper) {
        this.baseMapper = mapper;
    }
}
