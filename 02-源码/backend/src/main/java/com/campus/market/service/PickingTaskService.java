package com.campus.market.service;

import com.campus.market.entity.PickingTask;
import com.campus.market.mapper.PickingTaskMapper;
import org.springframework.stereotype.Service;

@Service
public class PickingTaskService extends BaseService<PickingTask> {
    public PickingTaskService(PickingTaskMapper mapper) {
        this.baseMapper = mapper;
    }
}
