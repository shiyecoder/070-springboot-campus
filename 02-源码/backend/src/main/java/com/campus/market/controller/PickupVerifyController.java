package com.campus.market.controller;

import com.campus.market.entity.PickupVerify;
import com.campus.market.service.PickupVerifyService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 核销记录标准 CRUD 接口，统一前缀 /api/pickup-verify */
@RestController
@RequestMapping("/api/pickup-verify-record")
public class PickupVerifyController extends BaseCrudController<PickupVerify> {

    private final PickupVerifyService service;

    public PickupVerifyController(PickupVerifyService service) {
        this.service = service;
    }

    @Override
    protected PickupVerifyService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"verify_no", "pickup_code", "verifier"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
