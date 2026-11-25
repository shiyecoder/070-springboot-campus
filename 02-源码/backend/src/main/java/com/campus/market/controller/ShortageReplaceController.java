package com.campus.market.controller;

import com.campus.market.entity.ShortageReplace;
import com.campus.market.service.ShortageReplaceService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 缺货替换标准 CRUD 接口，统一前缀 /api/shortage-replace */
@RestController
@RequestMapping("/api/shortage-replace")
public class ShortageReplaceController extends BaseCrudController<ShortageReplace> {

    private final ShortageReplaceService service;

    public ShortageReplaceController(ShortageReplaceService service) {
        this.service = service;
    }

    @Override
    protected ShortageReplaceService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"replace_no"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
