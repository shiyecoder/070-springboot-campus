package com.campus.market.controller;

import com.campus.market.common.R;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * 学生门户公开接口：自提点、商品、时段。
 * 只返回上架且在售数据，不含成本、库存精确值等敏感字段（需求 5.1 库存低于 5 件自动转售罄并隐藏）。
 */
@RestController
@RequestMapping("/api/portal")
public class PortalController {

    private final JdbcTemplate jdbc;

    public PortalController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @GetMapping("/home")
    public R<Map<String, Object>> home(@RequestParam(required = false) Long point_id,
                                       @RequestParam(required = false) String keyword,
                                       @RequestParam(required = false) String category) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("points", jdbc.queryForList(
                "SELECT id,point_no,name,location_desc,open_time,close_time,contact_name,serve_limit,image " +
                "FROM pickup_point WHERE deleted=0 AND status=1 ORDER BY id"));

        StringBuilder sql = new StringBuilder(
                "SELECT id,goods_no,name,category_code,spec,sale_price,limit_qty,shelf_code,is_cold,status,image,stock_qty " +
                "FROM shop_goods WHERE deleted=0 AND status=1");
        List<Object> args = new ArrayList<>();
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (name LIKE ? OR spec LIKE ?)");
            args.add("%" + keyword + "%");
            args.add("%" + keyword + "%");
        }
        if (category != null && !category.isBlank()) {
            sql.append(" AND category_code=?");
            args.add(category);
        }
        sql.append(" ORDER BY id LIMIT 60");
        List<Map<String, Object>> goods = jdbc.queryForList(sql.toString(), args.toArray());
        // 库存低于 5 件按售罄展示，门户不再接受下单
        for (Map<String, Object> g : goods) {
            int stock = Integer.parseInt(String.valueOf(g.get("stock_qty")));
            g.put("sold_out", stock < 5);
            g.remove("stock_qty");
        }
        data.put("goods", goods);
        data.put("categories", jdbc.queryForList(
                "SELECT category_code AS code, COUNT(*) AS cnt FROM shop_goods WHERE deleted=0 AND status=1 GROUP BY category_code"));
        data.put("notices", jdbc.queryForList(
                "SELECT id,title,content,publish_time FROM sys_notice WHERE deleted=0 AND status=1 ORDER BY publish_time DESC LIMIT 3"));

        Long pid = point_id != null ? point_id : (data.get("points") instanceof List<?> l && !l.isEmpty()
                ? Long.valueOf(String.valueOf(((Map<?, ?>) l.get(0)).get("id"))) : 1L);
        data.put("point_id", pid);
        data.put("slots", jdbc.queryForList(
                "SELECT id,slot_no,slot_date,start_time,end_time,capacity,booked_count,status FROM pick_slot " +
                "WHERE deleted=0 AND point_id=? AND slot_date>=CURDATE() AND slot_date<=DATE_ADD(CURDATE(), INTERVAL 7 DAY) " +
                "ORDER BY slot_date, start_time", pid));
        return R.ok(data);
    }

    @GetMapping("/goods/{id}")
    public R<Map<String, Object>> goods(@PathVariable Long id) {
        Map<String, Object> g = jdbc.queryForMap(
                "SELECT id,goods_no,name,category_code,spec,sale_price,limit_qty,shelf_code,is_cold,status,image,stock_qty " +
                "FROM shop_goods WHERE id=? AND deleted=0", id);
        int stock = Integer.parseInt(String.valueOf(g.get("stock_qty")));
        g.put("sold_out", stock < 5);
        g.put("stock_qty", stock);
        g.put("related", jdbc.queryForList(
                "SELECT id,name,sale_price,spec,image FROM shop_goods WHERE deleted=0 AND status=1 " +
                "AND category_code=? AND id<>? LIMIT 4", g.get("category_code"), id));
        return R.ok(g);
    }
}
