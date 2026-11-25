package com.campus.market.service;

import com.campus.market.entity.ShortageReplace;
import com.campus.market.mapper.ShortageReplaceMapper;
import org.springframework.stereotype.Service;

@Service
public class ShortageReplaceService extends BaseService<ShortageReplace> {
    public ShortageReplaceService(ShortageReplaceMapper mapper) {
        this.baseMapper = mapper;
    }
}
