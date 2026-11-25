package com.campus.market.controller;

import com.campus.market.entity.PickupPoint;
import com.campus.market.service.PickupPointService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 自提点标准 CRUD 接口，统一前缀 /api/pickup-point */
@RestController
@RequestMapping("/api/pickup-point")
public class PickupPointController extends BaseCrudController<PickupPoint> {

    private final PickupPointService service;

    public PickupPointController(PickupPointService service) {
        this.service = service;
    }

    @Override
    protected PickupPointService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"point_no", "name"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
