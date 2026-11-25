package com.campus.market.service;

import com.campus.market.entity.PickupOrder;
import com.campus.market.mapper.PickupOrderMapper;
import org.springframework.stereotype.Service;

@Service
public class PickupOrderService extends BaseService<PickupOrder> {
    public PickupOrderService(PickupOrderMapper mapper) {
        this.baseMapper = mapper;
    }
}
