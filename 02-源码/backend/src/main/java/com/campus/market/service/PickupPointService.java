package com.campus.market.service;

import com.campus.market.entity.PickupPoint;
import com.campus.market.mapper.PickupPointMapper;
import org.springframework.stereotype.Service;

@Service
public class PickupPointService extends BaseService<PickupPoint> {
    public PickupPointService(PickupPointMapper mapper) {
        this.baseMapper = mapper;
    }
}
