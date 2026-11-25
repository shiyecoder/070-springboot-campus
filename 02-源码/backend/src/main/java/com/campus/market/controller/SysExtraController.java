package com.campus.market.controller;

import com.campus.market.common.BizException;
import com.campus.market.common.R;
import com.campus.market.security.CurrentUser;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/** 文件上传与系统扩展接口：上传落盘 uploads/{bizType}/{yyyyMM}/，数据库只存相对路径 */
@RestController
@RequestMapping("/api")
public class SysExtraController {

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final Set<String> IMG = Set.of("jpg", "jpeg", "png", "webp");
    private static final Set<String> DOC = Set.of("pdf", "docx", "xlsx");

    private final JdbcTemplate jdbc;
    private final com.campus.market.service.OrderExpireJob expireJob;

    @Value("${campus.upload-dir:./uploads/}")
    private String uploadDir;

    public SysExtraController(JdbcTemplate jdbc, com.campus.market.service.OrderExpireJob expireJob) {
        this.jdbc = jdbc;
        this.expireJob = expireJob;
    }

    /** 上传：校验扩展名与大小，重命名后落盘并登记 sys_file */
    @PostMapping("/file/upload")
    public R<Map<String, Object>> upload(@RequestParam("file") MultipartFile file,
                                         @RequestParam(defaultValue = "common") String bizType) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new BizException(4000, "请选择要上传的文件");
        }
        String original = file.getOriginalFilename() == null ? "file" : file.getOriginalFilename();
        String ext = original.contains(".") ? original.substring(original.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!IMG.contains(ext) && !DOC.contains(ext)) {
            throw new BizException(4000, "只支持 jpg/png/webp 图片与 pdf/docx/xlsx 文档");
        }
        long limit = IMG.contains(ext) ? 5 * 1024 * 1024L : 20 * 1024 * 1024L;
        if (file.getSize() > limit) {
            throw new BizException(4000, "文件超过大小限制（图片 5MB，文档 20MB）");
        }
        String month = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"));
        Path dir = Paths.get(uploadDir, bizType, month).toAbsolutePath().normalize();
        Files.createDirectories(dir);
        String name = UUID.randomUUID().toString().replace("-", "") + "." + ext;
        Path target = dir.resolve(name);
        file.transferTo(target.toFile());
        String rel = "/uploads/" + bizType + "/" + month + "/" + name;
        jdbc.update("INSERT INTO sys_file(file_name,file_path,file_size,file_type,biz_type,uploader_id,create_time) " +
                        "VALUES(?,?,?,?,?,?,?)", original, rel, file.getSize(), ext, bizType, CurrentUser.id(),
                LocalDateTime.now().format(DT));
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("fileName", original);
        data.put("filePath", rel);
        data.put("fileSize", file.getSize());
        data.put("fileType", ext);
        return R.ok(data);
    }

    /** 角色已授权菜单 ID，用于「为角色分配菜单」树形勾选 */
    @GetMapping("/role/{id}/menus")
    public R<List<Long>> roleMenus(@PathVariable Long id) {
        return R.ok(jdbc.queryForList("SELECT menu_id FROM sys_role_menu WHERE role_id=?", Long.class, id));
    }

    /** 保存角色菜单授权：先清后插，剔除不存在的菜单 */
    @PutMapping("/role/{id}/menus")
    public R<Boolean> saveRoleMenus(@PathVariable Long id, @RequestBody Map<String, List<Long>> body) {
        List<Long> menuIds = body.getOrDefault("menu_ids", List.of());
        jdbc.update("DELETE FROM sys_role_menu WHERE role_id=?", id);
        for (Long mid : menuIds) {
            Integer exists = jdbc.queryForObject("SELECT COUNT(*) FROM sys_menu WHERE id=?", Integer.class, mid);
            if (exists != null && exists > 0) {
                jdbc.update("INSERT INTO sys_role_menu(role_id,menu_id) VALUES(?,?)", id, mid);
            }
        }
        return R.ok(true);
    }

    /** 未读消息数 + 最近消息 */
    @GetMapping("/sys-message/mine")
    public R<Map<String, Object>> myMessages() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("unread", jdbc.queryForObject(
                "SELECT COUNT(*) FROM sys_message WHERE receiver_id=? AND read_flag=0", Integer.class, CurrentUser.id()));
        data.put("list", jdbc.queryForList(
                "SELECT id,title,content,biz_type,biz_id,read_flag,create_time FROM sys_message " +
                "WHERE receiver_id=? ORDER BY id DESC LIMIT 10", CurrentUser.id()));
        return R.ok(data);
    }

    @PostMapping("/sys-message/{id}/read")
    public R<Boolean> read(@PathVariable Long id) {
        jdbc.update("UPDATE sys_message SET read_flag=1 WHERE id=? AND receiver_id=?", id, CurrentUser.id());
        return R.ok(true);
    }

    /** 手动触发一次超时作废扫描（管理员/店长），便于验证与补跑 */
    @PostMapping("/order-expire/scan")
    public R<Integer> expireScan() {
        if (!CurrentUser.hasRole("admin") && !CurrentUser.hasRole("manager")) {
            throw new BizException(4030, "仅管理员或门店店长可手动触发作废扫描");
        }
        return R.ok(expireJob.expireOnce());
    }
}
