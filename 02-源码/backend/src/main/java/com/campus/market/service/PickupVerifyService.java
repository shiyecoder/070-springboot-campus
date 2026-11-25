package com.campus.market.service;

import com.campus.market.entity.PickupVerify;
import com.campus.market.mapper.PickupVerifyMapper;
import org.springframework.stereotype.Service;

@Service
public class PickupVerifyService extends BaseService<PickupVerify> {
    public PickupVerifyService(PickupVerifyMapper mapper) {
        this.baseMapper = mapper;
    }
}
