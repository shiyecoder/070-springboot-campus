package com.campus.market.controller;

import com.campus.market.entity.PickSlot;
import com.campus.market.service.PickSlotService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 自提时段标准 CRUD 接口，统一前缀 /api/pick-slot */
@RestController
@RequestMapping("/api/pick-slot")
public class PickSlotController extends BaseCrudController<PickSlot> {

    private final PickSlotService service;

    public PickSlotController(PickSlotService service) {
        this.service = service;
    }

    @Override
    protected PickSlotService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"slot_no"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
