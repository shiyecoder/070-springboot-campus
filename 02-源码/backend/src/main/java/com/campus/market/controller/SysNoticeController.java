package com.campus.market.controller;

import com.campus.market.entity.SysNotice;
import com.campus.market.service.SysNoticeService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 公告标准 CRUD 接口，统一前缀 /api/sys-notice */
@RestController
@RequestMapping("/api/sys-notice")
public class SysNoticeController extends BaseCrudController<SysNotice> {

    private final SysNoticeService service;

    public SysNoticeController(SysNoticeService service) {
        this.service = service;
    }

    @Override
    protected SysNoticeService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"title"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
