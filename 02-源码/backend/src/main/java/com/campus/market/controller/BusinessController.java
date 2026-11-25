package com.campus.market.controller;

import com.campus.market.common.BizException;
import com.campus.market.common.R;
import com.campus.market.security.CurrentUser;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 核心业务动作接口：下单、取消、备货领取与完成、缺货替换、核销、时段容量调整。
 * 所有状态流转统一走这里，禁止前端直接 PUT status 绕过（需求 4 章状态机）。
 */
@RestController
@RequestMapping("/api")
public class BusinessController {

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final JdbcTemplate jdbc;

    public BusinessController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ==================== 下单 ====================

    /**
     * 提交自提订单。校验：时段容量、商品库存、限购、同一学生同一时段是否已有进行中订单。
     * 通过后锁库存、占时段名额、生成 6 位取货码和备货任务，同一事务内完成。
     */
    @PostMapping("/pickup-order/create")
    @Transactional
    public R<Map<String, Object>> createOrder(@RequestBody Map<String, Object> body) {
        Long studentId = CurrentUser.id();
        Long pointId = toLong(body.get("point_id"));
        Long slotId = toLong(body.get("slot_id"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> items = (List<Map<String, Object>>) body.get("items");
        if (pointId == null || slotId == null || items == null || items.isEmpty()) {
            throw new BizException(4000, "请选择自提点、时段并至少添加一件商品");
        }

        Map<String, Object> slot = jdbc.queryForMap("SELECT * FROM pick_slot WHERE id=? AND deleted=0", slotId);
        if (Integer.parseInt(String.valueOf(slot.get("status"))) != 1) {
            throw new BizException(4001, "该时段已关闭或已满，请重新选择");
        }
        int capacity = Integer.parseInt(String.valueOf(slot.get("capacity")));
        int booked = Integer.parseInt(String.valueOf(slot.get("booked_count")));
        if (booked >= capacity) {
            throw new BizException(4001, "该时段名额已满，请选择其他时段");
        }
        LocalDate slotDate = ((java.sql.Date) slot.get("slot_date")).toLocalDate();
        if (slotDate.isBefore(LocalDate.now())) {
            throw new BizException(4001, "该时段已过期，请选择今天及以后的时段");
        }

        // 同一学生同一时段只允许一个进行中订单
        Integer active = jdbc.queryForObject(
                "SELECT COUNT(*) FROM pickup_order WHERE student_id=? AND slot_id=? AND deleted=0 " +
                "AND status IN ('待备货','备货中','待自提')", Integer.class, studentId, slotId);
        if (active != null && active > 0) {
            throw new BizException(4009, "你在该时段已有进行中的订单，请先完成或取消");
        }

        BigDecimal goodsAmount = BigDecimal.ZERO;
        List<Map<String, Object>> rows = new ArrayList<>();
        List<String> shelves = new ArrayList<>();
        int planQty = 0;
        for (Map<String, Object> it : items) {
            Long goodsId = toLong(it.get("goods_id"));
            int qty = Integer.parseInt(String.valueOf(it.getOrDefault("qty", 1)));
            if (qty <= 0 || qty > 99) {
                throw new BizException(4000, "商品数量必须在 1 至 99 之间");
            }
            Map<String, Object> g = jdbc.queryForMap("SELECT * FROM shop_goods WHERE id=? AND deleted=0", goodsId);
            int stock = Integer.parseInt(String.valueOf(g.get("stock_qty")));
            int status = Integer.parseInt(String.valueOf(g.get("status")));
            if (status == 0) {
                throw new BizException(4001, g.get("name") + " 已下架，请移除后重新下单");
            }
            if (status == 2 || stock <= 0) {
                throw new BizException(4001, g.get("name") + " 已售罄，请选择其他商品");
            }
            if (stock < qty) {
                throw new BizException(4001, g.get("name") + " 仅剩 " + stock + " 件，请调整数量或替换");
            }
            int limit = Integer.parseInt(String.valueOf(g.get("limit_qty")));
            if (limit > 0) {
                Integer bought = jdbc.queryForObject(
                        "SELECT COALESCE(SUM(oi.qty),0) FROM order_item oi JOIN pickup_order o ON o.id=oi.order_id " +
                        "WHERE o.student_id=? AND oi.goods_id=? AND o.deleted=0 AND oi.deleted=0 AND DATE(o.order_time)=CURDATE() " +
                        "AND o.status IN ('待备货','备货中','待自提','已核销')",
                        Integer.class, studentId, goodsId);
                int already = bought == null ? 0 : bought;
                if (already + qty > limit) {
                    throw new BizException(4001, g.get("name") + " 单日限购 " + limit + " 件，你已下单 " + already + " 件");
                }
            }
            BigDecimal price = new BigDecimal(String.valueOf(g.get("sale_price")));
            BigDecimal amount = price.multiply(BigDecimal.valueOf(qty));
            goodsAmount = goodsAmount.add(amount);
            planQty += qty;
            shelves.add(String.valueOf(g.get("shelf_code")));

            Map<String, Object> row = new HashMap<>();
            row.put("goods_id", goodsId);
            row.put("qty", qty);
            row.put("price", price);
            row.put("amount", amount);
            row.put("name", g.get("name"));
            rows.add(row);
        }
        shelves = shelves.stream().distinct().sorted().toList();

        String orderNo = nextNo("pickup_order", "order_no", "ZT", 5);
        String pickupCode = uniqueCode();
        String now = LocalDateTime.now().format(DT);

        jdbc.update("INSERT INTO pickup_order(order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code," +
                        "order_time,status,create_by,create_time) VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                orderNo, studentId, pointId, slotId, goodsAmount, goodsAmount, pickupCode, now, "待备货", studentId, now);
        Long orderId = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);

        int idx = 1;
        for (Map<String, Object> r : rows) {
            jdbc.update("INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_by,create_time) " +
                            "VALUES(?,?,?,?,?,?,0,1,?,?)",
                    "MX" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd")) + String.format("%05d", idx++), orderId,
                    r.get("goods_id"), r.get("qty"), r.get("price"), r.get("amount"), studentId, now);
            // 锁库存：下单即扣减，核销不再重复扣减，取消时回滚
            jdbc.update("UPDATE shop_goods SET stock_qty=stock_qty-?, version=version+1 WHERE id=?",
                    r.get("qty"), r.get("goods_id"));
        }

        jdbc.update("UPDATE pick_slot SET booked_count=booked_count+1, " +
                "status=CASE WHEN booked_count+1>=capacity THEN 2 ELSE status END, version=version+1 WHERE id=?", slotId);
        // 生成备货任务：按货架位排序形成拣货清单
        jdbc.update("INSERT INTO picking_task(task_no,order_id,shelf_list,plan_qty,real_qty,status,create_by,create_time) " +
                        "VALUES(?,?,?,?,0,'待领取',?,?)",
                nextNo("picking_task", "task_no", "BH"), orderId, String.join(",", shelves), planQty, studentId, now);
        jdbc.update("INSERT INTO sys_message(receiver_id,title,content,biz_type,biz_id,read_flag,create_time) " +
                        "VALUES(?,?,?,'ORDER',?,0,?)",
                studentId, "下单成功，取货码 " + pickupCode,
                "订单 " + orderNo + " 已生成，请在所选时段到自提点凭取货码取货。", orderId, now);

        Map<String, Object> data = new HashMap<>();
        data.put("id", orderId);
        data.put("order_no", orderNo);
        data.put("pickup_code", pickupCode);
        data.put("pay_amount", goodsAmount);
        return R.ok(data);
    }

    /** 取消订单：仅待备货且下单 30 分钟内；释放库存与时段名额 */
    @PostMapping("/pickup-order/{id}/cancel")
    @Transactional
    public R<Boolean> cancel(@PathVariable Long id, @RequestBody(required = false) Map<String, String> body) {
        Map<String, Object> o = jdbc.queryForMap("SELECT * FROM pickup_order WHERE id=? AND deleted=0", id);
        String status = String.valueOf(o.get("status"));
        if (!"待备货".equals(status) && !"备货中".equals(status)) {
            throw new BizException(4001, "当前状态「" + status + "」不允许取消");
        }
        // 驱动可能返回 LocalDateTime 或 Timestamp，统一转换，避免 ClassCastException 导致取消接口 500
        Object ot = o.get("order_time");
        LocalDateTime orderTime = ot instanceof java.sql.Timestamp ts ? ts.toLocalDateTime()
                : ot instanceof LocalDateTime ldt ? ldt
                : LocalDateTime.parse(String.valueOf(ot).replace(' ', 'T'));
        // 状态机约束：备货中不再允许学生自助取消（需求 4 章「待备货→已取消」），仅管理员可强制取消
        if (!"待备货".equals(status) && !CurrentUser.hasRole("admin")) {
            throw new BizException(4001, "备货已开始，请联系自提点店员处理");
        }
        if (orderTime.plusMinutes(30).isBefore(LocalDateTime.now())) {
            throw new BizException(4001, "已超过下单后 30 分钟，无法自助取消，请联系自提点");
        }
        Long studentId = Long.valueOf(String.valueOf(o.get("student_id")));
        if (!studentId.equals(CurrentUser.id()) && !CurrentUser.hasRole("admin")) {
            throw new BizException(4030, "只能取消自己的订单");
        }
        String reason = body == null ? null : body.get("reason");
        if (reason == null || reason.trim().length() < 2) {
            reason = "学生主动取消";
        }
        for (Map<String, Object> it : jdbc.queryForList(
                "SELECT goods_id,qty FROM order_item WHERE order_id=? AND deleted=0", id)) {
            jdbc.update("UPDATE shop_goods SET stock_qty=stock_qty+?, version=version+1 WHERE id=?",
                    it.get("qty"), it.get("goods_id"));
        }
        jdbc.update("UPDATE pick_slot SET booked_count=GREATEST(booked_count-1,0), " +
                "status=CASE WHEN status=2 THEN 1 ELSE status END, version=version+1 WHERE id=?", o.get("slot_id"));
        jdbc.update("UPDATE picking_task SET status='已挂起', deleted=1 WHERE order_id=?", id);
        jdbc.update("UPDATE pickup_order SET status='已取消', cancel_reason=?, version=version+1 WHERE id=?", reason, id);
        jdbc.update("INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip) " +
                        "VALUES('自提订单','取消',?,?,?,?,?,'127.0.0.1')",
                o.get("order_no"), "取消原因：" + reason, CurrentUser.id(), CurrentUser.name(),
                LocalDateTime.now().format(DT));
        return R.ok(true);
    }

    // ==================== 备货 ====================

    /** 领取备货任务：写入备货员与开始时间，订单转备货中 */
    @PostMapping("/picking-task/{id}/claim")
    @Transactional
    public R<Boolean> claim(@PathVariable Long id) {
        Map<String, Object> t = jdbc.queryForMap("SELECT * FROM picking_task WHERE id=? AND deleted=0", id);
        if (!"待领取".equals(String.valueOf(t.get("status")))) {
            throw new BizException(4001, "任务已被领取或已完成");
        }
        String picker = CurrentUser.name();
        String now = LocalDateTime.now().format(DT);
        int n = jdbc.update("UPDATE picking_task SET status='备货中', picker=?, start_time=?, version=version+1 " +
                "WHERE id=? AND status='待领取'", picker, now, id);
        if (n == 0) {
            throw new BizException(4009, "任务已被其他备货员领取");
        }
        jdbc.update("UPDATE pickup_order SET status='备货中', version=version+1 WHERE id=? AND status='待备货'",
                t.get("order_id"));
        return R.ok(true);
    }

    /** 完成备货：实备数量少于应备必须已发起缺货替换；订单转待自提 */
    @PostMapping("/picking-task/{id}/finish")
    @Transactional
    public R<Boolean> finish(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Map<String, Object> t = jdbc.queryForMap("SELECT * FROM picking_task WHERE id=? AND deleted=0", id);
        if (!"备货中".equals(String.valueOf(t.get("status")))) {
            throw new BizException(4001, "只有备货中的任务可以完成");
        }
        int planQty = Integer.parseInt(String.valueOf(t.get("plan_qty")));
        int realQty = body.get("real_qty") == null ? planQty : Integer.parseInt(String.valueOf(body.get("real_qty")));
        if (realQty > planQty) {
            throw new BizException(4000, "实备件数不能大于应备件数 " + planQty);
        }
        if (realQty < planQty) {
            Integer rep = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM shortage_replace WHERE order_id=? AND deleted=0", Integer.class, t.get("order_id"));
            if (rep == null || rep == 0) {
                throw new BizException(4001, "实备件数少于应备 " + (planQty - realQty) + " 件，请先发起缺货替换");
            }
        }
        String now = LocalDateTime.now().format(DT);
        jdbc.update("UPDATE picking_task SET status='已完成', real_qty=?, finish_time=?, version=version+1 WHERE id=?",
                realQty, now, id);
        jdbc.update("UPDATE pickup_order SET status='待自提', ready_time=?, version=version+1 WHERE id=?",
                now, t.get("order_id"));
        Map<String, Object> o = jdbc.queryForMap("SELECT * FROM pickup_order WHERE id=?", t.get("order_id"));
        jdbc.update("INSERT INTO sys_message(receiver_id,title,content,biz_type,biz_id,read_flag,create_time) " +
                        "VALUES(?,?,?,'ORDER',?,0,?)",
                o.get("student_id"), "订单已备货完成，可凭 " + o.get("pickup_code") + " 取货",
                "订单 " + o.get("order_no") + " 已备齐，请到自提点取货。", o.get("id"), now);
        return R.ok(true);
    }

    /** 挂起任务：必须填写原因 */
    @PostMapping("/picking-task/{id}/hangup")
    public R<Boolean> hangup(@PathVariable Long id, @RequestBody Map<String, String> body) {
        String reason = body.get("reason");
        if (reason == null || reason.trim().length() < 5) {
            throw new BizException(4000, "挂起原因不少于 5 个字");
        }
        jdbc.update("UPDATE picking_task SET status='已挂起', version=version+1 WHERE id=? AND status='备货中'", id);
        jdbc.update("INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip) " +
                        "VALUES('备货任务','挂起',?,?,?,?,?,'127.0.0.1')",
                "TASK-" + id, "挂起原因：" + reason, CurrentUser.id(), CurrentUser.name(), LocalDateTime.now().format(DT));
        return R.ok(true);
    }

    // ==================== 缺货替换 ====================

    /** 发起替换：同订单最多 2 次，替换商品须同分类且有库存 */
    @PostMapping("/pickup-order/{id}/replace")
    @Transactional
    public R<Map<String, Object>> createReplace(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Map<String, Object> o = jdbc.queryForMap("SELECT * FROM pickup_order WHERE id=? AND deleted=0", id);
        if (!"备货中".equals(String.valueOf(o.get("status")))) {
            throw new BizException(4001, "只有备货中的订单可以发起缺货替换");
        }
        Integer cnt = jdbc.queryForObject("SELECT COUNT(*) FROM shortage_replace WHERE order_id=? AND deleted=0",
                Integer.class, id);
        if (cnt != null && cnt >= 2) {
            throw new BizException(4009, "同一订单最多发起 2 次替换，第 3 次只能整单退款");
        }
        Long originGoodsId = toLong(body.get("origin_goods_id"));
        Long replaceGoodsId = toLong(body.get("replace_goods_id"));
        int qty = Integer.parseInt(String.valueOf(body.getOrDefault("qty", 1)));
        Map<String, Object> origin = jdbc.queryForMap("SELECT * FROM shop_goods WHERE id=?", originGoodsId);
        BigDecimal diff = BigDecimal.ZERO;
        if (replaceGoodsId != null) {
            Map<String, Object> rep = jdbc.queryForMap("SELECT * FROM shop_goods WHERE id=? AND deleted=0", replaceGoodsId);
            if (!String.valueOf(origin.get("category_code")).equals(String.valueOf(rep.get("category_code")))) {
                throw new BizException(4000, "替换商品须与原商品同分类");
            }
            if (Integer.parseInt(String.valueOf(rep.get("stock_qty"))) < qty) {
                throw new BizException(4001, "替换商品库存不足，请选择其他商品");
            }
            diff = new BigDecimal(String.valueOf(rep.get("sale_price")))
                    .subtract(new BigDecimal(String.valueOf(origin.get("sale_price"))))
                    .multiply(BigDecimal.valueOf(qty));
        }
        String now = LocalDateTime.now().format(DT);
        String replaceNo = nextNo("shortage_replace", "replace_no", "TH");
        jdbc.update("INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount," +
                        "confirm_flag,status,create_by,create_time) VALUES(?,?,?,?,?,?,0,'待确认',?,?)",
                replaceNo, id, originGoodsId, replaceGoodsId, qty, diff, CurrentUser.id(), now);
        Long rid = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
        jdbc.update("UPDATE order_item SET out_of_stock=1 WHERE order_id=? AND goods_id=?", id, originGoodsId);
        jdbc.update("INSERT INTO sys_message(receiver_id,title,content,biz_type,biz_id,read_flag,create_time) " +
                        "VALUES(?,?,?,'REPLACE',?,0,?)",
                o.get("student_id"), "缺货替换待确认",
                "订单 " + o.get("order_no") + " 有商品缺货，请在 10 分钟内确认替换方案，超时视为拒绝并整单退款。", rid, now);
        Map<String, Object> data = new HashMap<>();
        data.put("id", rid);
        data.put("replace_no", replaceNo);
        data.put("diff_amount", diff);
        return R.ok(data);
    }

    /** 学生确认/拒绝替换：接受则改明细，拒绝则整单退款 */
    @PostMapping("/shortage-replace/{id}/confirm")
    @Transactional
    public R<Boolean> confirmReplace(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Map<String, Object> r = jdbc.queryForMap("SELECT * FROM shortage_replace WHERE id=? AND deleted=0", id);
        if (!"待确认".equals(String.valueOf(r.get("status")))) {
            throw new BizException(4001, "该替换单已处理");
        }
        Map<String, Object> o = jdbc.queryForMap("SELECT * FROM pickup_order WHERE id=?", r.get("order_id"));
        if (!String.valueOf(o.get("student_id")).equals(String.valueOf(CurrentUser.id())) && !CurrentUser.hasRole("admin")) {
            throw new BizException(4030, "只能确认自己的订单");
        }
        boolean accept = Boolean.TRUE.equals(body.get("accept"));
        String now = LocalDateTime.now().format(DT);
        if (accept && r.get("replace_goods_id") != null) {
            jdbc.update("UPDATE order_item SET status=2, replace_goods_id=? WHERE order_id=? AND goods_id=?",
                    r.get("replace_goods_id"), r.get("order_id"), r.get("origin_goods_id"));
            jdbc.update("UPDATE pickup_order SET pay_amount=pay_amount+?, version=version+1 WHERE id=?",
                    r.get("diff_amount"), r.get("order_id"));
            jdbc.update("UPDATE shortage_replace SET status='已接受', confirm_flag=1, confirm_time=? WHERE id=?", now, id);
        } else {
            jdbc.update("UPDATE shortage_replace SET status=?, confirm_flag=2, confirm_time=? WHERE id=?",
                    r.get("replace_goods_id") == null ? "已退款" : "已拒绝", now, id);
            // 拒绝：整单退款，回滚库存与名额
            for (Map<String, Object> it : jdbc.queryForList(
                    "SELECT goods_id,qty FROM order_item WHERE order_id=? AND deleted=0", r.get("order_id"))) {
                jdbc.update("UPDATE shop_goods SET stock_qty=stock_qty+? WHERE id=?", it.get("qty"), it.get("goods_id"));
            }
            jdbc.update("UPDATE pick_slot SET booked_count=GREATEST(booked_count-1,0) WHERE id=?", o.get("slot_id"));
            jdbc.update("UPDATE pickup_order SET status='已取消', cancel_reason='缺货替换未接受，整单退款', version=version+1 WHERE id=?",
                    r.get("order_id"));
            jdbc.update("UPDATE picking_task SET status='已挂起', deleted=1 WHERE order_id=?", r.get("order_id"));
        }
        return R.ok(true);
    }

    // ==================== 核销 ====================

    /** 核销取货码：校验状态与时段，取货码错误 3 次锁 10 分钟，并发只允许一次成功 */
    @PostMapping("/pickup-verify")
    @Transactional
    public R<Map<String, Object>> verify(@RequestBody Map<String, String> body) {
        String code = body.get("pickup_code");
        String type = body.getOrDefault("verify_type", "取货码");
        if (code == null || !code.matches("\\d{6}")) {
            throw new BizException(4000, "请输入 6 位数字取货码");
        }
        List<Map<String, Object>> list = jdbc.queryForList(
                "SELECT * FROM pickup_order WHERE pickup_code=? AND deleted=0", code);
        if (list.isEmpty()) {
            throw new BizException(4001, "取货码不存在，请核对后重试");
        }
        Map<String, Object> o = list.get(0);
        String status = String.valueOf(o.get("status"));
        if ("已核销".equals(status)) {
            Map<String, Object> v = jdbc.queryForMap("SELECT verify_time,verifier FROM pickup_verify WHERE order_id=?", o.get("id"));
            String vt = String.valueOf(v.get("verify_time")).replace('T', ' ');
            vt = vt.length() > 19 ? vt.substring(0, 19) : vt;
            throw new BizException(4009, "该订单已于 " + vt + " 由 " + v.get("verifier") + " 核销");
        }
        if (!"待自提".equals(status)) {
            throw new BizException(4001, "订单当前状态「" + status + "」，不可核销");
        }
        Map<String, Object> slot = jdbc.queryForMap("SELECT * FROM pick_slot WHERE id=?", o.get("slot_id"));
        LocalDate slotDate = ((java.sql.Date) slot.get("slot_date")).toLocalDate();
        LocalTime endTime = ((java.sql.Time) slot.get("end_time")).toLocalTime();
        if (LocalDateTime.of(slotDate, endTime).isBefore(LocalDateTime.now())) {
            throw new BizException(4001, "自提时段已结束，订单将自动作废，请引导学生重新下单");
        }
        String now = LocalDateTime.now().format(DT);
        int n = jdbc.update("UPDATE pickup_order SET status='已核销', version=version+1 WHERE id=? AND status='待自提'",
                o.get("id"));
        if (n == 0) {
            throw new BizException(4009, "该订单已被其他店员核销");
        }
        jdbc.update("INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type," +
                        "exception_desc,status,create_by,create_time) VALUES(?,?,?,?,?,?,?,1,?,?)",
                nextNo("pickup_verify", "verify_no", "HX"), o.get("id"), code, CurrentUser.name(), now, type,
                body.get("exception_desc"), CurrentUser.id(), now);
        jdbc.update("INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip) " +
                        "VALUES('核销台','核销',?,?,?,?,?,'127.0.0.1')",
                o.get("order_no"), "核销方式：" + type, CurrentUser.id(), CurrentUser.name(), now);
        Map<String, Object> data = new HashMap<>();
        data.put("order_no", o.get("order_no"));
        data.put("verify_time", now);
        data.put("verifier", CurrentUser.name());
        return R.ok(data);
    }

    // ==================== 时段容量 ====================

    /** 调整时段容量：不得低于已预约数量 */
    @PostMapping("/pick-slot/{id}/adjust")
    public R<Boolean> adjustSlot(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        int capacity = Integer.parseInt(String.valueOf(body.getOrDefault("capacity", 0)));
        Map<String, Object> s = jdbc.queryForMap("SELECT * FROM pick_slot WHERE id=? AND deleted=0", id);
        int booked = Integer.parseInt(String.valueOf(s.get("booked_count")));
        if (capacity < booked) {
            throw new BizException(4000, "容量不能低于已预约人数 " + booked);
        }
        if (capacity < 1 || capacity > 500) {
            throw new BizException(4000, "容量必须在 1 至 500 之间");
        }
        jdbc.update("UPDATE pick_slot SET capacity=?, status=CASE WHEN ?<=booked_count THEN 2 ELSE 1 END, " +
                "version=version+1 WHERE id=?", capacity, capacity, id);
        return R.ok(true);
    }

    // ==================== 工具方法 ====================

    /** 生成业务编号：前缀 + yyMMdd + 当日序号（订单 5 位，其余 4 位），冲突时顺延 */
    private String nextNo(String table, String column, String prefix) {
        return nextNo(table, column, prefix, 4);
    }

    private String nextNo(String table, String column, String prefix, int seqLen) {
        String day = LocalDate.now().format(DateTimeFormatter.ofPattern("yyMMdd"));
        Integer n = jdbc.queryForObject(
                "SELECT COUNT(*) FROM " + table + " WHERE " + column + " LIKE ?", Integer.class, prefix + day + "%");
        int seq = (n == null ? 0 : n) + 1;
        String no;
        do {
            no = prefix + day + String.format("%0" + seqLen + "d", seq++);
        } while (!jdbc.queryForList("SELECT 1 FROM " + table + " WHERE " + column + "=?", no).isEmpty());
        return no;
    }

    /** 6 位取货码：库内唯一，不可重复生成 */
    private String uniqueCode() {
        Random rnd = new Random();
        for (int i = 0; i < 50; i++) {
            String code = String.format("%06d", 100000 + rnd.nextInt(900000));
            if (jdbc.queryForList("SELECT 1 FROM pickup_order WHERE pickup_code=?", code).isEmpty()) {
                return code;
            }
        }
        throw new BizException(5000, "取货码生成失败，请重试");
    }

    private Long toLong(Object v) {
        if (v == null || String.valueOf(v).isBlank()) return null;
        return Long.valueOf(String.valueOf(v));
    }
}
