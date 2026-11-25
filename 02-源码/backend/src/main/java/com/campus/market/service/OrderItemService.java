package com.campus.market.service;

import com.campus.market.entity.OrderItem;
import com.campus.market.mapper.OrderItemMapper;
import org.springframework.stereotype.Service;

@Service
public class OrderItemService extends BaseService<OrderItem> {
    public OrderItemService(OrderItemMapper mapper) {
        this.baseMapper = mapper;
    }
}
