package com.campus.market.controller;

import com.campus.market.entity.SysRole;
import com.campus.market.service.SysRoleService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 角色标准 CRUD 接口，统一前缀 /api/sys-role */
@RestController
@RequestMapping("/api/sys-role")
public class SysRoleController extends BaseCrudController<SysRole> {

    private final SysRoleService service;

    public SysRoleController(SysRoleService service) {
        this.service = service;
    }

    @Override
    protected SysRoleService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"role_name", "role_code"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
