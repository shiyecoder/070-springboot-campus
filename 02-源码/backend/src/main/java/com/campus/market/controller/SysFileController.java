package com.campus.market.controller;

import com.campus.market.entity.SysFile;
import com.campus.market.service.SysFileService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 文件标准 CRUD 接口，统一前缀 /api/sys-file */
@RestController
@RequestMapping("/api/sys-file")
public class SysFileController extends BaseCrudController<SysFile> {

    private final SysFileService service;

    public SysFileController(SysFileService service) {
        this.service = service;
    }

    @Override
    protected SysFileService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"file_name", "file_path"};
    }

    @Override
    protected String statusColumn() {
        return null;
    }
}
