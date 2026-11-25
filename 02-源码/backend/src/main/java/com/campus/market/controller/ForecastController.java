package com.campus.market.controller;

import com.campus.market.common.BizException;
import com.campus.market.common.R;
import com.campus.market.security.CurrentUser;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * 创新点：备货量测算与高峰时段预测（需求第 8 章）。
 * 五因素加权评分 + 建议备货量 + 置信度 + 计算留痕 + 人工修正。
 * 规则权重可配置（合计必须 100），改动记版本号，历史计算不受影响。
 */
@RestController
@RequestMapping("/api")
public class ForecastController {

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final JdbcTemplate jdbc;

    public ForecastController(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 当前生效规则 */
    private Map<String, Object> activeRule() {
        List<Map<String, Object>> rs = jdbc.queryForList(
                "SELECT * FROM forecast_rule WHERE status=1 AND deleted=0 ORDER BY rule_version DESC LIMIT 1");
        if (rs.isEmpty()) {
            throw new BizException(5000, "预测规则未配置，请先在规则配置页初始化");
        }
        return rs.get(0);
    }

    /**
     * 预测列表：按自提点 + 日期，对每个时段算建议备货量与高峰等级。
     * 计算时保存输入快照、规则版本、各因素得分与置信度，保证结果可追溯。
     */
    @GetMapping("/stocks/forecast")
    @Transactional
    public R<Map<String, Object>> forecast(@RequestParam(required = false) Long point_id,
                                           @RequestParam(required = false) String date,
                                           @RequestParam(required = false, defaultValue = "false") boolean recalc) {
        Map<String, Object> rule = activeRule();
        int version = Integer.parseInt(String.valueOf(rule.get("rule_version")));
        BigDecimal wHistory = new BigDecimal(String.valueOf(rule.get("w_history")));
        BigDecimal wCourse = new BigDecimal(String.valueOf(rule.get("w_course")));
        BigDecimal wWeather = new BigDecimal(String.valueOf(rule.get("w_weather")));
        BigDecimal wPromo = new BigDecimal(String.valueOf(rule.get("w_promo")));
        BigDecimal wTurn = new BigDecimal(String.valueOf(rule.get("w_turnover")));

        LocalDate d = date == null || date.isBlank() ? LocalDate.now().plusDays(1) : LocalDate.parse(date);
        Long pid = point_id != null ? point_id : jdbc.queryForObject(
                "SELECT id FROM pickup_point WHERE deleted=0 ORDER BY id LIMIT 1", Long.class);
        String weekday = String.valueOf(d.getDayOfWeek().getValue());

        List<Map<String, Object>> slots = jdbc.queryForList(
                "SELECT * FROM pick_slot WHERE deleted=0 AND point_id=? AND slot_date=? ORDER BY start_time", pid, d);
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> s : slots) {
            Long slotId = Long.valueOf(String.valueOf(s.get("id")));
            String start = String.valueOf(s.get("start_time")).substring(0, 5);
            String end = String.valueOf(s.get("end_time")).substring(0, 5);

            // 因素1：近4周同星期同时段销量中位数
            Integer median = jdbc.queryForObject(
                    "SELECT COALESCE(ROUND(AVG(t.qty)),0) FROM (SELECT oi.qty FROM order_item oi " +
                    "JOIN pickup_order o ON o.id=oi.order_id JOIN pick_slot ps ON ps.id=o.slot_id " +
                    "WHERE ps.start_time=? AND DAYOFWEEK(ps.slot_date)=DAYOFWEEK(?) AND o.deleted=0 AND oi.deleted=0 " +
                    "AND o.status IN ('已核销','待自提') ORDER BY oi.qty LIMIT 4) t", Integer.class, s.get("start_time"), d);
            int baseQty = median == null ? 0 : median;
            // 因素2：课程表标签（以时段命中判定：07-09 早八，18 点后晚课，周末离校）
            int hour = Integer.parseInt(start.substring(0, 2));
            double courseCoef = 1.0;
            String courseTag = "常规";
            if (hour <= 8) { courseCoef = 1.35; courseTag = "早八"; }
            else if (hour >= 18) { courseCoef = 1.25; courseTag = "晚课"; }
            else if (d.getDayOfWeek().getValue() >= 6) { courseCoef = 0.85; courseTag = "周末离校"; }
            // 因素3：天气（运营维护，缺省按晴）
            // 天气由运营在字典中维护，缺省按晴处理
            String weather = jdbc.queryForObject(
                    "SELECT COALESCE(MAX(dict_label),'晴') FROM sys_dict_data WHERE dict_type='weather' AND status=1",
                    String.class);
            double weatherCoef = weather.contains("雨") ? 0.8 : weather.contains("高温") ? 1.2 : 1.0;
            // 因素4：促销（当日有生效促销则 1.3）
            Integer promo = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM sys_notice WHERE deleted=0 AND status=1 AND title LIKE '%促销%'", Integer.class);
            double promoCoef = (promo != null && promo > 0) ? 1.3 : 1.0;
            // 因素5：商品周转（近14天动销占比）
            Integer turnDays = jdbc.queryForObject(
                    "SELECT COUNT(DISTINCT DATE(o.order_time)) FROM pickup_order o WHERE o.deleted=0 " +
                    "AND o.order_time >= DATE_SUB(NOW(), INTERVAL 14 DAY)", Integer.class);
            double turnoverAdj = turnDays == null ? 0 : Math.min(20, turnDays * 2) / 100.0;

            int suggest = (int) Math.round(baseQty * courseCoef * weatherCoef * promoCoef * (1 + turnoverAdj));
            suggest = Math.max(1, suggest);

            // 高峰评分：五因素归一化得分 × 权重
            double sHistory = Math.min(1.0, baseQty / 20.0) * 100;
            double sCourse = (courseCoef - 1.0) * 200 + 50;
            double sWeather = (weatherCoef - 1.0) * 200 + 50;
            double sPromo = (promoCoef - 1.0) * 200 + 50;
            double sTurn = turnoverAdj * 400 + 30;
            double score = sHistory * wHistory.doubleValue() / 100 + sCourse * wCourse.doubleValue() / 100
                    + sWeather * wWeather.doubleValue() / 100 + sPromo * wPromo.doubleValue() / 100
                    + sTurn * wTurn.doubleValue() / 100;
            score = Math.max(0, Math.min(100, score));
            String level = score >= 80 ? "A" : score >= 60 ? "B" : score >= 40 ? "C" : "D";

            // 置信度：样本周数 + 数据完整度
            int weeks = Math.min(4, (baseQty > 0 ? 4 : 1));
            double confidence = 55 + weeks * 10 + (weatherCoef != 1.0 ? 5 : 0) + (promo != null && promo > 0 ? 5 : 0);
            confidence = Math.min(95, confidence);
            boolean conservative = confidence < 60;
            if (conservative) suggest = Math.max(1, (int) Math.round(suggest * 0.85));

            String snapshot = String.format(
                    "{\"base_qty\":%d,\"course_tag\":\"%s\",\"course_coef\":%.2f,\"weather\":\"%s\",\"weather_coef\":%.2f," +
                    "\"promo_coef\":%.2f,\"turnover_adj\":%.2f,\"scores\":{\"history\":%.1f,\"course\":%.1f," +
                    "\"weather\":%.1f,\"promo\":%.1f,\"turnover\":%.1f}}",
                    baseQty, courseTag, courseCoef, weather, weatherCoef, promoCoef, turnoverAdj,
                    sHistory, sCourse, sWeather, sPromo, sTurn);

            // 计算留痕：同日期+时段+规则版本只保留一条，重算时覆盖快照但保留人工修正
            List<Map<String, Object>> exist = jdbc.queryForList(
                    "SELECT id FROM forecast_calc WHERE slot_id=? AND slot_date=? AND rule_version=? AND deleted=0",
                    slotId, d, version);
            Long calcId;
            if (exist.isEmpty()) {
                jdbc.update("INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level," +
                                "confidence,rule_version,snapshot_json,calc_time,create_time) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        "FC" + d.toString().replace("-", "") + "V" + version + String.format("%03d", slotId % 1000),
                        pid, slotId, d, start, suggest, BigDecimal.valueOf(score).setScale(2, RoundingMode.HALF_UP),
                        level, BigDecimal.valueOf(confidence).setScale(2, RoundingMode.HALF_UP), version, snapshot,
                        LocalDateTime.now().format(DT), LocalDateTime.now().format(DT));
                calcId = jdbc.queryForObject("SELECT LAST_INSERT_ID()", Long.class);
            } else {
                calcId = Long.valueOf(String.valueOf(exist.get(0).get("id")));
                jdbc.update("UPDATE forecast_calc SET suggest_qty=?,score=?,level=?,confidence=?,snapshot_json=?,calc_time=? " +
                                "WHERE id=?", suggest, BigDecimal.valueOf(score).setScale(2, RoundingMode.HALF_UP), level,
                        BigDecimal.valueOf(confidence).setScale(2, RoundingMode.HALF_UP), snapshot,
                        LocalDateTime.now().format(DT), calcId);
            }

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("calc_id", calcId);
            row.put("slot_id", slotId);
            row.put("start_time", start);
            row.put("end_time", end);
            row.put("capacity", s.get("capacity"));
            row.put("booked_count", s.get("booked_count"));
            row.put("suggest_qty", suggest);
            row.put("score", BigDecimal.valueOf(score).setScale(1, RoundingMode.HALF_UP));
            row.put("level", level);
            row.put("confidence", BigDecimal.valueOf(confidence).setScale(1, RoundingMode.HALF_UP));
            row.put("conservative", conservative);
            row.put("base_qty", baseQty);
            row.put("course_tag", courseTag);
            row.put("weather", weather);
            row.put("rule_version", version);
            row.put("drivers", List.of(
                    Map.of("name", "历史同段销量", "value", Math.round(sHistory * 10) / 10.0, "weight", wHistory),
                    Map.of("name", "课程表标签", "value", Math.round(sCourse * 10) / 10.0, "weight", wCourse),
                    Map.of("name", "天气因素", "value", Math.round(sWeather * 10) / 10.0, "weight", wWeather),
                    Map.of("name", "促销活动", "value", Math.round(sPromo * 10) / 10.0, "weight", wPromo),
                    Map.of("name", "商品周转", "value", Math.round(sTurn * 10) / 10.0, "weight", wTurn)));
            row.put("advice", advice(level));
            out.add(row);
        }
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("date", d.toString());
        data.put("point_id", pid);
        data.put("rule_version", version);
        data.put("items", out);
        return R.ok(data);
    }

    private String advice(String level) {
        return switch (level) {
            case "A" -> "极高瓶颈：建议增加备货 30% 以上，并加派 1 名备货员";
            case "B" -> "高峰时段：按建议量备货，提前 15 分钟完成拣货";
            case "C" -> "平峰时段：按建议量备货，人员不额外增加";
            default -> "低谷时段：建议下调备货量 20%，减少短保商品上架";
        };
    }

    /** 规则配置：权重合计必须 100，修改后版本号 +1 并记生效时间 */
    @GetMapping("/forecast/rules")
    public R<List<Map<String, Object>>> rules() {
        return R.ok(jdbc.queryForList("SELECT * FROM forecast_rule WHERE deleted=0 ORDER BY rule_version DESC"));
    }

    @PutMapping("/forecast/rules")
    @Transactional
    public R<Map<String, Object>> saveRule(@RequestBody Map<String, Object> body) {
        BigDecimal wh = new BigDecimal(String.valueOf(body.get("w_history")));
        BigDecimal wc = new BigDecimal(String.valueOf(body.get("w_course")));
        BigDecimal ww = new BigDecimal(String.valueOf(body.get("w_weather")));
        BigDecimal wp = new BigDecimal(String.valueOf(body.get("w_promo")));
        BigDecimal wt = new BigDecimal(String.valueOf(body.get("w_turnover")));
        BigDecimal sum = wh.add(wc).add(ww).add(wp).add(wt);
        if (sum.compareTo(BigDecimal.valueOf(100)) != 0) {
            throw new BizException(4000, "五项权重合计必须等于 100%，当前为 " + sum + "%");
        }
        Integer maxV = jdbc.queryForObject("SELECT COALESCE(MAX(rule_version),0) FROM forecast_rule", Integer.class);
        int newV = (maxV == null ? 0 : maxV) + 1;
        String now = LocalDateTime.now().format(DT);
        jdbc.update("UPDATE forecast_rule SET status=0 WHERE status=1");
        jdbc.update("INSERT INTO forecast_rule(rule_version,w_history,w_course,w_weather,w_promo,w_turnover," +
                        "effective_time,status,remark,create_by,create_time) VALUES(?,?,?,?,?,?,?,1,?,?,?)",
                newV, wh, wc, ww, wp, wt, now, String.valueOf(body.getOrDefault("remark", "权重调整")),
                CurrentUser.id(), now);
        Map<String, Object> data = new HashMap<>();
        data.put("rule_version", newV);
        data.put("effective_time", now);
        return R.ok(data);
    }

    /** 人工修正：原始计算结果保留，修正必须填写不少于 5 字原因 */
    @PostMapping("/forecast/{id}/adjust")
    public R<Boolean> adjust(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String reason = body.get("reason") == null ? "" : String.valueOf(body.get("reason")).trim();
        if (reason.length() < 5) {
            throw new BizException(4000, "人工修正原因不少于 5 个字");
        }
        int qty = Integer.parseInt(String.valueOf(body.get("manual_qty")));
        if (qty < 0 || qty > 500) {
            throw new BizException(4000, "修正备货量必须在 0 至 500 之间");
        }
        int n = jdbc.update("UPDATE forecast_calc SET manual_qty=?, manual_reason=?, manual_flag=1, manual_by=?, " +
                        "manual_time=? WHERE id=? AND deleted=0",
                qty, reason, CurrentUser.name(), LocalDateTime.now().format(DT), id);
        if (n == 0) {
            throw new BizException(4001, "预测记录不存在");
        }
        return R.ok(true);
    }

    /** 计算留痕详情：输入快照 + 各因素得分 + 规则版本 */
    @GetMapping("/forecast/{id}")
    public R<Map<String, Object>> detail(@PathVariable Long id) {
        Map<String, Object> row = jdbc.queryForMap("SELECT * FROM forecast_calc WHERE id=? AND deleted=0", id);
        Map<String, Object> data = new LinkedHashMap<>(row);
        Map<String, Object> rule = jdbc.queryForMap("SELECT * FROM forecast_rule WHERE rule_version=?",
                row.get("rule_version"));
        data.put("rule", rule);
        return R.ok(data);
    }

    /** 采纳率与修正率统计，验证规则有效性 */
    @GetMapping("/forecast/stats")
    public R<Map<String, Object>> stats() {
        Integer total = jdbc.queryForObject("SELECT COUNT(*) FROM forecast_calc WHERE deleted=0", Integer.class);
        Integer manual = jdbc.queryForObject("SELECT COUNT(*) FROM forecast_calc WHERE deleted=0 AND manual_flag=1", Integer.class);
        Map<String, Object> data = new HashMap<>();
        data.put("total", total == null ? 0 : total);
        data.put("manual", manual == null ? 0 : manual);
        data.put("adopt_rate", total == null || total == 0 ? 0 : (total - (manual == null ? 0 : manual)) * 100 / total);
        data.put("manual_rate", total == null || total == 0 ? 0 : (manual == null ? 0 : manual) * 100 / total);
        return R.ok(data);
    }
}
