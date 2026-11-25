package com.campus.market.service;

import com.campus.market.entity.PickSlot;
import com.campus.market.mapper.PickSlotMapper;
import org.springframework.stereotype.Service;

@Service
public class PickSlotService extends BaseService<PickSlot> {
    public PickSlotService(PickSlotMapper mapper) {
        this.baseMapper = mapper;
    }
}
