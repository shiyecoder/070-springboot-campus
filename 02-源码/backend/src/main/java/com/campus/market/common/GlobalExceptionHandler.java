package com.campus.market.common;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.validation.BindException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** 全局异常处理：把校验失败、重复提交、业务异常翻译成统一错误码 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public R<Void> handleBiz(BizException e) {
        return R.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public R<Void> handleValid(Exception e) {
        String msg = "参数校验失败";
        if (e instanceof MethodArgumentNotValidException m && m.getBindingResult().getFieldError() != null) {
            msg = m.getBindingResult().getFieldError().getDefaultMessage();
        } else if (e instanceof BindException b && b.getFieldError() != null) {
            msg = b.getFieldError().getDefaultMessage();
        }
        return R.fail(4000, msg);
    }

    @ExceptionHandler(DuplicateKeyException.class)
    public R<Void> handleDup(DuplicateKeyException e) {
        return R.fail(4009, "重复提交或重复操作，记录已存在");
    }

    @ExceptionHandler(Exception.class)
    public R<Void> handleOther(Exception e) {
        e.printStackTrace();
        return R.fail(5000, "服务器异常：" + e.getMessage());
    }
}
