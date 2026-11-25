package com.campus.market.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * 超时作废定时任务（需求 4 章状态机：待自提→超时作废；需求 11 章：时段结束 2 小时后自动作废）。
 * 处理逻辑：待备货/备货中/待自提三类进行中订单，若自提时段结束时间已过 2 小时，
 * 则在同一事务内回滚商品库存（临期流程）、关闭备货任务、写状态原因、记操作日志并给店长发站内消息。
 * 每 5 分钟扫描一次，单次最多处理 200 单，避免长事务。
 */
@Service
public class OrderExpireJob {

    private static final Logger log = LoggerFactory.getLogger(OrderExpireJob.class);
    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final String REASON = "自提时段结束2小时后系统自动作废";

    private final JdbcTemplate jdbc;

    public OrderExpireJob(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** 扫描并作废超时订单，返回本次处理条数（供手动触发与测试调用） */
    @Transactional
    public int expireOnce() {
        String sql = "SELECT o.id,o.order_no,o.status,o.slot_id FROM pickup_order o " +
                "JOIN pick_slot s ON s.id=o.slot_id " +
                "WHERE o.deleted=0 AND o.status IN ('待备货','备货中','待自提') " +
                "AND TIMESTAMP(s.slot_date,s.end_time) < DATE_SUB(NOW(), INTERVAL 2 HOUR) " +
                "ORDER BY o.id LIMIT 200";
        List<Map<String, Object>> list = jdbc.queryForList(sql);
        String now = LocalDateTime.now().format(DT);
        int done = 0;
        for (Map<String, Object> o : list) {
            Long orderId = Long.valueOf(String.valueOf(o.get("id")));
            // 幂等：仅当状态仍为进行中才更新，避免与人工取消/核销并发重复回滚
            int n = jdbc.update("UPDATE pickup_order SET status='超时作废', cancel_reason=?, " +
                    "update_time=?, version=version+1 WHERE id=? AND status=?", REASON, now, orderId, o.get("status"));
            if (n == 0) {
                continue;
            }
            for (Map<String, Object> it : jdbc.queryForList(
                    "SELECT goods_id,qty FROM order_item WHERE order_id=? AND deleted=0", orderId)) {
                jdbc.update("UPDATE shop_goods SET stock_qty=stock_qty+?, version=version+1 WHERE id=?",
                        it.get("qty"), it.get("goods_id"));
            }
            jdbc.update("UPDATE picking_task SET status='已作废', version=version+1 WHERE order_id=? AND deleted=0", orderId);
            jdbc.update("INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip) " +
                            "VALUES('自提订单','超时作废',?,?,1,'系统任务',?,'127.0.0.1')",
                    o.get("order_no"), "超过自提时段结束 2 小时自动作废，库存已回滚", now);
            jdbc.update("INSERT INTO sys_message(receiver_id,title,content,biz_type,biz_id,read_flag,create_time) " +
                            "VALUES(NULL,'订单超时作废提醒',?,'超时提醒',?,0,?)",
                    "订单 " + o.get("order_no") + " 超过自提时段 2 小时未取货，已自动作废并回滚库存，请核对临期商品。",
                    orderId, now);
            done++;
        }
        if (done > 0) {
            log.info("超时作废任务处理 {} 笔订单", done);
        }
        return done;
    }

    /** 每 5 分钟执行一次，首次延迟 30 秒（等应用启动完成） */
    @Scheduled(initialDelay = 30_000, fixedDelay = 300_000)
    public void run() {
        try {
            expireOnce();
        } catch (Exception e) {
            log.warn("超时作废任务异常：{}", e.getMessage());
        }
    }
}
