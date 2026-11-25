package com.campus.market.controller;

import com.campus.market.entity.SysDictData;
import com.campus.market.service.SysDictDataService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 字典数据标准 CRUD 接口，统一前缀 /api/sys-dict-data */
@RestController
@RequestMapping("/api/sys-dict-data")
public class SysDictDataController extends BaseCrudController<SysDictData> {

    private final SysDictDataService service;

    public SysDictDataController(SysDictDataService service) {
        this.service = service;
    }

    @Override
    protected SysDictDataService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"dict_label", "dict_value"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
