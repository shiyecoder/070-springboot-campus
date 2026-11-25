package com.campus.market.controller;

import com.campus.market.entity.SysMessage;
import com.campus.market.service.SysMessageService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 站内消息标准 CRUD 接口，统一前缀 /api/sys-message */
@RestController
@RequestMapping("/api/sys-message")
public class SysMessageController extends BaseCrudController<SysMessage> {

    private final SysMessageService service;

    public SysMessageController(SysMessageService service) {
        this.service = service;
    }

    @Override
    protected SysMessageService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"title", "content"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
