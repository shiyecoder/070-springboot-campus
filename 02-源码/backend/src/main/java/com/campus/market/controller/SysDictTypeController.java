package com.campus.market.controller;

import com.campus.market.entity.SysDictType;
import com.campus.market.service.SysDictTypeService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 字典类型标准 CRUD 接口，统一前缀 /api/sys-dict-type */
@RestController
@RequestMapping("/api/sys-dict-type")
public class SysDictTypeController extends BaseCrudController<SysDictType> {

    private final SysDictTypeService service;

    public SysDictTypeController(SysDictTypeService service) {
        this.service = service;
    }

    @Override
    protected SysDictTypeService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"dict_name", "dict_type"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
