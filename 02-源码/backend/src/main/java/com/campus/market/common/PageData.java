package com.campus.market.common;

import lombok.Data;

import java.util.List;

/** 分页返回：records/total/page/size/pages */
@Data
public class PageData<T> {
    private List<T> records;
    private long total;
    private long page;
    private long size;
    private long pages;

    public PageData(List<T> records, long total, long page, long size) {
        this.records = records;
        this.total = total;
        this.page = page;
        this.size = size;
        this.pages = size == 0 ? 0 : (total + size - 1) / size;
    }
}
