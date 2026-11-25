package com.campus.market.controller;

import com.campus.market.entity.SysOperLog;
import com.campus.market.service.SysOperLogService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 操作日志标准 CRUD 接口，统一前缀 /api/sys-oper-log */
@RestController
@RequestMapping("/api/sys-oper-log")
public class SysOperLogController extends BaseCrudController<SysOperLog> {

    private final SysOperLogService service;

    public SysOperLogController(SysOperLogService service) {
        this.service = service;
    }

    @Override
    protected SysOperLogService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"module", "biz_no", "content"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
