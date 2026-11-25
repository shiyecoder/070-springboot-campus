package com.campus.market.controller;

import com.campus.market.common.BizException;
import com.campus.market.common.R;
import com.campus.market.entity.SysUser;
import com.campus.market.security.CurrentUser;
import com.campus.market.security.JwtUtil;
import com.campus.market.service.SysUserService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * 登录、当前用户信息、动态菜单、字典。
 * 菜单按「角色-菜单」关系动态下发，前端不写死菜单项（需求 2 章权限三层控制）。
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final SysUserService userService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final JdbcTemplate jdbc;

    public AuthController(SysUserService userService, PasswordEncoder passwordEncoder,
                          JwtUtil jwtUtil, JdbcTemplate jdbc) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.jdbc = jdbc;
    }

    /** 登录：校验密码、账号状态，签发 JWT 并回传角色编码 */
    @PostMapping("/login")
    public R<Map<String, Object>> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");
        if (username == null || password == null) {
            throw new BizException(4000, "用户名和密码不能为空");
        }
        SysUser user = userService.lambdaQuery().eq(SysUser::getUsername, username).one();
        if (user == null || !passwordEncoder.matches(password, user.getPassword())) {
            throw new BizException(4010, "用户名或密码错误");
        }
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BizException(4030, "账号已停用，请联系管理员");
        }
        List<Map<String, Object>> roles = jdbc.queryForList(
                "SELECT r.role_code, r.role_name FROM sys_user_role ur JOIN sys_role r ON r.id=ur.role_id WHERE ur.user_id=?",
                user.getId());
        String roleCodes = roles.stream().map(m -> String.valueOf(m.get("role_code")))
                .reduce("", (a, b) -> a.isEmpty() ? b : a + "," + b);
        String token = jwtUtil.create(user.getId(), user.getUsername(), roleCodes);
        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        data.put("user_id", user.getId());
        data.put("username", user.getUsername());
        data.put("real_name", user.getRealName());
        data.put("avatar", user.getAvatar());
        data.put("dept_name", user.getDeptName());
        data.put("roles", roleCodes);
        data.put("role_names", roles.stream().map(m -> m.get("role_name")).toList());
        return R.ok(data);
    }

    @GetMapping("/info")
    public R<Map<String, Object>> info() {
        SysUser user = userService.getById(CurrentUser.id());
        if (user == null) {
            throw new BizException(4010, "登录已失效");
        }
        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("real_name", user.getRealName());
        data.put("phone", user.getPhone());
        data.put("avatar", user.getAvatar());
        data.put("email", user.getEmail());
        data.put("dept_name", user.getDeptName());
        data.put("credit_score", user.getCreditScore());
        data.put("roles", jdbc.queryForList(
                "SELECT r.role_code, r.role_name, r.data_scope FROM sys_user_role ur JOIN sys_role r ON r.id=ur.role_id WHERE ur.user_id=?",
                user.getId()));
        return R.ok(data);
    }

    /** 动态菜单：目录(M)+菜单(C) 返回树，按钮(B) 作为权限标识单独返回 */
    @GetMapping("/menus")
    public R<Map<String, Object>> menus() {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT DISTINCT m.id, m.parent_id, m.menu_name, m.path, m.component, m.perms, m.icon, m.type, m.sort_no " +
                "FROM sys_menu m JOIN sys_role_menu rm ON rm.menu_id=m.id JOIN sys_user_role ur ON ur.role_id=rm.role_id " +
                "WHERE ur.user_id=? AND m.visible=1 AND m.status=1 ORDER BY m.sort_no", CurrentUser.id());
        List<Map<String, Object>> menus = new ArrayList<>();
        List<String> perms = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            if ("B".equals(String.valueOf(r.get("type")))) {
                perms.add(String.valueOf(r.get("perms")));
            } else {
                Map<String, Object> m = new HashMap<>();
                m.put("id", r.get("id"));
                m.put("parent_id", r.get("parent_id"));
                m.put("menu_name", r.get("menu_name"));
                m.put("path", r.get("path"));
                m.put("component", r.get("component"));
                m.put("perms", r.get("perms"));
                m.put("icon", r.get("icon"));
                m.put("type", r.get("type"));
                m.put("sort_no", r.get("sort_no"));
                menus.add(m);
            }
        }
        Map<String, Object> data = new HashMap<>();
        data.put("menus", menus);
        data.put("perms", perms);
        return R.ok(data);
    }

    /** 字典查询：页面下拉统一从这里取，禁止前端硬编码枚举 */
    @GetMapping("/dict/{type}")
    public R<List<Map<String, Object>>> dict(@PathVariable String type) {
        return R.ok(jdbc.queryForList(
                "SELECT dict_label, dict_value FROM sys_dict_data WHERE dict_type=? AND status=1 ORDER BY sort_no", type));
    }

    @GetMapping("/dict-all")
    public R<Map<String, Object>> dictAll() {
        List<Map<String, Object>> rows = jdbc.queryForList(
                "SELECT dict_type, dict_label, dict_value FROM sys_dict_data WHERE status=1 ORDER BY dict_type, sort_no");
        Map<String, Object> out = new LinkedHashMap<>();
        for (Map<String, Object> r : rows) {
            String t = String.valueOf(r.get("dict_type"));
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> list = (List<Map<String, Object>>) out.computeIfAbsent(t, k -> new ArrayList<>());
            Map<String, Object> item = new HashMap<>();
            item.put("label", r.get("dict_label"));
            item.put("value", r.get("dict_value"));
            list.add(item);
        }
        return R.ok(out);
    }

    @PostMapping("/logout")
    public R<Boolean> logout() {
        return R.ok(true);
    }

    /** 个人信息：改资料、改密码、上传头像（头像路径由上传接口返回） */
    @PutMapping("/profile")
    public R<Boolean> profile(@RequestBody Map<String, String> body) {
        SysUser u = userService.getById(CurrentUser.id());
        if (u == null) {
            throw new BizException(4010, "登录已失效");
        }
        if (body.get("real_name") != null) u.setRealName(body.get("real_name"));
        if (body.get("phone") != null) u.setPhone(body.get("phone"));
        if (body.get("email") != null) u.setEmail(body.get("email"));
        if (body.get("avatar") != null) u.setAvatar(body.get("avatar"));
        if (body.get("new_password") != null && !body.get("new_password").isBlank()) {
            if (!passwordEncoder.matches(body.getOrDefault("old_password", ""), u.getPassword())) {
                throw new BizException(4000, "原密码不正确");
            }
            u.setPassword(passwordEncoder.encode(body.get("new_password")));
        }
        return R.ok(userService.updateById(u));
    }
}
