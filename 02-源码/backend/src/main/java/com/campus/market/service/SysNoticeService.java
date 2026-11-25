package com.campus.market.service;

import com.campus.market.entity.SysNotice;
import com.campus.market.mapper.SysNoticeMapper;
import org.springframework.stereotype.Service;

@Service
public class SysNoticeService extends BaseService<SysNotice> {
    public SysNoticeService(SysNoticeMapper mapper) {
        this.baseMapper = mapper;
    }
}
