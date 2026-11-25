package com.campus.market.controller;

import com.campus.market.entity.SysUser;
import com.campus.market.service.SysUserService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 用户标准 CRUD 接口，统一前缀 /api/sys-user */
@RestController
@RequestMapping("/api/sys-user")
public class SysUserController extends BaseCrudController<SysUser> {

    private final SysUserService service;

    public SysUserController(SysUserService service) {
        this.service = service;
    }

    @Override
    protected SysUserService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"username", "real_name", "phone"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
