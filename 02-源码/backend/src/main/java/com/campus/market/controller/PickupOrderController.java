package com.campus.market.controller;

import com.campus.market.entity.PickupOrder;
import com.campus.market.service.PickupOrderService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 自提订单标准 CRUD 接口，统一前缀 /api/pickup-order */
@RestController
@RequestMapping("/api/pickup-order")
public class PickupOrderController extends BaseCrudController<PickupOrder> {

    private final PickupOrderService service;

    public PickupOrderController(PickupOrderService service) {
        this.service = service;
    }

    @Override
    protected PickupOrderService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"order_no", "pickup_code"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
