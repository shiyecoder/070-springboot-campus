package com.campus.market.controller;

import com.campus.market.entity.PickingTask;
import com.campus.market.service.PickingTaskService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 备货任务标准 CRUD 接口，统一前缀 /api/picking-task */
@RestController
@RequestMapping("/api/picking-task")
public class PickingTaskController extends BaseCrudController<PickingTask> {

    private final PickingTaskService service;

    public PickingTaskController(PickingTaskService service) {
        this.service = service;
    }

    @Override
    protected PickingTaskService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"task_no", "picker"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
