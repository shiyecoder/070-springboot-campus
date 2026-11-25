package com.campus.market.controller;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campus.market.common.BizException;
import com.campus.market.common.PageData;
import com.campus.market.common.R;
import com.campus.market.service.BaseService;
import org.springframework.web.bind.annotation.*;

/**
 * 通用 CRUD 控制器：分页、详情、新增、修改、删除五个标准接口由各业务控制器复用。
 * 子类只声明服务、关键字检索列与状态列，避免逐表重复代码。
 */
public abstract class BaseCrudController<T> {

    protected abstract BaseService<T> svc();

    /** 关键字模糊匹配的列（数据库列名） */
    protected abstract String[] keywordColumns();

    /** 状态筛选列，无则返回 null */
    protected String statusColumn() {
        return "status";
    }

    /** 排序列，默认按创建时间倒序 */
    protected String orderColumn() {
        return "create_time";
    }

    @GetMapping("/page")
    public R<PageData<T>> page(@RequestParam(defaultValue = "1") long page,
                               @RequestParam(defaultValue = "10") long size,
                               @RequestParam(required = false) String keyword,
                               @RequestParam(required = false) String status,
                               @RequestParam(required = false) String startTime,
                               @RequestParam(required = false) String endTime) {
        size = Math.min(Math.max(size, 1), 100);
        QueryWrapper<T> qw = new QueryWrapper<>();
        if (keyword != null && !keyword.isBlank()) {
            String[] cols = keywordColumns();
            qw.and(w -> {
                for (int i = 0; i < cols.length; i++) {
                    if (i == 0) {
                        w.like(cols[i], keyword);
                    } else {
                        w.or().like(cols[i], keyword);
                    }
                }
            });
        }
        if (status != null && !status.isBlank() && statusColumn() != null) {
            qw.eq(statusColumn(), status);
        }
        if (startTime != null && !startTime.isBlank()) {
            qw.ge(orderColumn(), startTime);
        }
        if (endTime != null && !endTime.isBlank()) {
            qw.le(orderColumn(), endTime);
        }
        qw.orderByDesc(orderColumn());
        Page<T> p = svc().page(new Page<>(page, size), qw);
        return R.ok(new PageData<>(p.getRecords(), p.getTotal(), page, size));
    }

    @GetMapping("/{id}")
    public R<T> detail(@PathVariable Long id) {
        T t = svc().getById(id);
        if (t == null) {
            throw new BizException(4001, "记录不存在或已删除");
        }
        return R.ok(t);
    }

    @PostMapping
    public R<Long> create(@RequestBody T body) {
        svc().save(body);
        return R.ok(null);
    }

    @PutMapping("/{id}")
    public R<Boolean> update(@PathVariable Long id, @RequestBody T body) {
        boolean ok = svc().updateById(body);
        if (!ok) {
            throw new BizException(4090, "数据已被他人更新，请刷新后重试");
        }
        return R.ok(true);
    }

    @DeleteMapping("/{id}")
    public R<Boolean> delete(@PathVariable Long id) {
        return R.ok(svc().removeById(id));
    }
}
