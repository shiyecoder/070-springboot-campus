package com.campus.market.controller;

import com.campus.market.entity.OrderItem;
import com.campus.market.service.OrderItemService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 订单明细标准 CRUD 接口，统一前缀 /api/order-item */
@RestController
@RequestMapping("/api/order-item")
public class OrderItemController extends BaseCrudController<OrderItem> {

    private final OrderItemService service;

    public OrderItemController(OrderItemService service) {
        this.service = service;
    }

    @Override
    protected OrderItemService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"item_no"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
