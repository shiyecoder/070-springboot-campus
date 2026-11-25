package com.campus.market.controller;

import com.campus.market.entity.SysMenu;
import com.campus.market.service.SysMenuService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 菜单标准 CRUD 接口，统一前缀 /api/sys-menu */
@RestController
@RequestMapping("/api/sys-menu")
public class SysMenuController extends BaseCrudController<SysMenu> {

    private final SysMenuService service;

    public SysMenuController(SysMenuService service) {
        this.service = service;
    }

    @Override
    protected SysMenuService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"menu_name", "path", "perms"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
