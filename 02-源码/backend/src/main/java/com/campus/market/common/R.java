package com.campus.market.common;

import lombok.Data;

/** 统一响应结构：code=0 成功，非 0 为业务错误码 */
@Data
public class R<T> {
    private int code;
    private String message;
    private T data;
    private String requestId;

    public static <T> R<T> ok(T data) {
        R<T> r = new R<>();
        r.code = 0;
        r.message = "success";
        r.data = data;
        r.requestId = "req-" + System.currentTimeMillis();
        return r;
    }

    public static <T> R<T> ok() {
        return ok(null);
    }

    public static <T> R<T> fail(int code, String message) {
        R<T> r = new R<>();
        r.code = code;
        r.message = message;
        r.requestId = "req-" + System.currentTimeMillis();
        return r;
    }
}
