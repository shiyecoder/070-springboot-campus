package com.campus.market.security;

/** 当前登录用户上下文（由 JwtAuthFilter 写入，请求结束清理） */
public class CurrentUser {
    private static final ThreadLocal<Long> ID = new ThreadLocal<>();
    private static final ThreadLocal<String> NAME = new ThreadLocal<>();
    private static final ThreadLocal<String> ROLES = new ThreadLocal<>();

    public static void set(Long id, String name, String roles) {
        ID.set(id);
        NAME.set(name);
        ROLES.set(roles);
    }

    public static Long id() {
        return ID.get() == null ? 1L : ID.get();
    }

    public static String name() {
        return NAME.get() == null ? "系统" : NAME.get();
    }

    public static String roles() {
        return ROLES.get() == null ? "" : ROLES.get();
    }

    public static boolean hasRole(String role) {
        return roles().contains(role);
    }

    public static void clear() {
        ID.remove();
        NAME.remove();
        ROLES.remove();
    }
}
