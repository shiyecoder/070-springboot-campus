-- ============================================================
-- 校园超市线上订货与自提系统（NEW-070）数据库初始化脚本
-- 库：new_070  字符集：utf8mb4  可重复执行
-- 包含：19 张表（8 业务 + 11 通用 + 2 预测留痕） + 字典/菜单/角色/账号/测试数据
-- ============================================================
DROP DATABASE IF EXISTS `new_070`;
CREATE DATABASE `new_070` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `new_070`;
SET NAMES utf8mb4;


-- ---------- 建表 ----------
CREATE TABLE `shop_goods` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `goods_no` varchar(32) NOT NULL COMMENT '规则 CS+yyMMdd+4位序号，全局唯一',
  `name` varchar(80) NOT NULL COMMENT '4至40字，含规格关键字',
  `category_code` varchar(30) NOT NULL COMMENT '饮料/零食/文具/日用品/生鲜/面包',
  `spec` varchar(40) NOT NULL COMMENT '如 500ml、80g、A5笔记本',
  `sale_price` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '0.01至999.99',
  `stock_qty` int NOT NULL DEFAULT 0 COMMENT '0至9999，下单锁库',
  `limit_qty` int NOT NULL DEFAULT 0 COMMENT '0表示不限购',
  `shelf_code` varchar(20) NOT NULL COMMENT '格式 区-排-位',
  `is_cold` tinyint NOT NULL DEFAULT 0 COMMENT '1冷藏 0常温',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1在售 0已下架 2已售罄',
  `image` varchar(200) DEFAULT NULL COMMENT '商品图相对路径',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_goods_no` (`goods_no`),
  KEY `idx_category_status` (`category_code`, `status`),
  KEY `idx_shelf` (`shelf_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='校园超市商品';

CREATE TABLE `pickup_point` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `point_no` varchar(32) NOT NULL COMMENT '规则 ZD+3位序号',
  `name` varchar(60) NOT NULL COMMENT '自提点名称',
  `location_desc` varchar(200) NOT NULL COMMENT '位置说明',
  `open_time` time NOT NULL DEFAULT '07:00:00' COMMENT '营业开始',
  `close_time` time NOT NULL DEFAULT '22:30:00' COMMENT '营业结束',
  `contact_name` varchar(30) NOT NULL COMMENT '联系人',
  `contact_phone` varchar(20) NOT NULL COMMENT '联系电话',
  `serve_limit` int NOT NULL DEFAULT 5 COMMENT '最大同时服务人数',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `image` varchar(200) DEFAULT NULL COMMENT '自提点照片相对路径',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_point_no` (`point_no`),
  KEY `idx_name_status` (`name`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自提点';

CREATE TABLE `pickup_order` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_no` varchar(32) NOT NULL COMMENT '规则 ZT+yyMMdd+5位序号',
  `student_id` bigint NOT NULL COMMENT '关联 sys_user.id',
  `point_id` bigint NOT NULL COMMENT '关联 pickup_point.id',
  `slot_id` bigint NOT NULL COMMENT '关联 pick_slot.id',
  `goods_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '商品金额',
  `pay_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '实付金额',
  `pickup_code` varchar(6) NOT NULL COMMENT '6位取货码',
  `order_time` datetime NOT NULL COMMENT '下单时间',
  `ready_time` datetime DEFAULT NULL COMMENT '备货完成时间',
  `cancel_reason` varchar(200) DEFAULT NULL COMMENT '取消或作废原因',
  `status` varchar(20) NOT NULL DEFAULT '待备货' COMMENT '待备货/备货中/待自提/已核销/已取消/超时作废',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  UNIQUE KEY `uk_pickup_code` (`pickup_code`),
  KEY `idx_student_status` (`student_id`, `status`),
  KEY `idx_point_slot` (`point_id`, `slot_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自提订单';

CREATE TABLE `order_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `item_no` varchar(32) NOT NULL COMMENT '规则 MX+yyMMdd+5位序号',
  `order_id` bigint NOT NULL COMMENT '关联 pickup_order.id',
  `goods_id` bigint NOT NULL COMMENT '关联 shop_goods.id',
  `qty` int NOT NULL DEFAULT 1 COMMENT '1至99',
  `price` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '下单快照价',
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '小计',
  `out_of_stock` tinyint NOT NULL DEFAULT 0 COMMENT '1缺货 0正常',
  `replace_goods_id` bigint DEFAULT NULL COMMENT '替换商品',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1正常 0已退款 2已替换',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_item_no` (`item_no`),
  KEY `idx_order` (`order_id`),
  KEY `idx_goods_status` (`goods_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细';

CREATE TABLE `pick_slot` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `slot_no` varchar(32) NOT NULL COMMENT '规则 SD+yyMMdd+3位序号',
  `point_id` bigint NOT NULL COMMENT '关联 pickup_point.id',
  `slot_date` date NOT NULL COMMENT '自提日期',
  `start_time` time NOT NULL COMMENT '开始时间',
  `end_time` time NOT NULL COMMENT '结束时间',
  `capacity` int NOT NULL DEFAULT 30 COMMENT '1至500',
  `booked_count` int NOT NULL DEFAULT 0 COMMENT '已预约',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1开放 0关闭 2已满',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_slot_no` (`slot_no`),
  UNIQUE KEY `uk_point_date_start` (`point_id`, `slot_date`, `start_time`),
  KEY `idx_date_status` (`slot_date`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自提时段';

CREATE TABLE `picking_task` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `task_no` varchar(32) NOT NULL COMMENT '规则 BH+yyMMdd+4位序号',
  `order_id` bigint NOT NULL COMMENT '关联 pickup_order.id，一单一任务',
  `picker` varchar(30) DEFAULT NULL COMMENT '备货员',
  `shelf_list` varchar(200) NOT NULL COMMENT '货架位汇总',
  `plan_qty` int NOT NULL DEFAULT 0 COMMENT '应备件数',
  `real_qty` int NOT NULL DEFAULT 0 COMMENT '实备件数',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `finish_time` datetime DEFAULT NULL COMMENT '完成时间',
  `status` varchar(20) NOT NULL DEFAULT '待领取' COMMENT '待领取/备货中/已完成/已挂起',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_no` (`task_no`),
  UNIQUE KEY `uk_order` (`order_id`),
  KEY `idx_status_start` (`status`, `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='备货任务';

CREATE TABLE `shortage_replace` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `replace_no` varchar(32) NOT NULL COMMENT '规则 TH+yyMMdd+4位序号',
  `order_id` bigint NOT NULL COMMENT '关联 pickup_order.id',
  `origin_goods_id` bigint NOT NULL COMMENT '原商品',
  `replace_goods_id` bigint DEFAULT NULL COMMENT '替换商品，空为直接退款',
  `qty` int NOT NULL DEFAULT 1 COMMENT '数量',
  `diff_amount` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT '差价',
  `confirm_flag` tinyint NOT NULL DEFAULT 0 COMMENT '0待确认 1接受 2拒绝',
  `confirm_time` datetime DEFAULT NULL COMMENT '确认时间',
  `status` varchar(20) NOT NULL DEFAULT '待确认' COMMENT '待确认/已接受/已拒绝/已退款',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_replace_no` (`replace_no`),
  KEY `idx_order_status` (`order_id`, `status`),
  KEY `idx_goods` (`origin_goods_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='缺货替换';

CREATE TABLE `pickup_verify` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `verify_no` varchar(32) NOT NULL COMMENT '规则 HX+yyMMdd+4位序号',
  `order_id` bigint NOT NULL COMMENT '关联 pickup_order.id',
  `pickup_code` varchar(6) NOT NULL COMMENT '取货码',
  `verifier` varchar(30) NOT NULL COMMENT '核销人',
  `verify_time` datetime NOT NULL COMMENT '核销时间',
  `verify_type` varchar(20) NOT NULL COMMENT '扫码/取货码/人工补录',
  `exception_desc` varchar(300) DEFAULT NULL COMMENT '异常说明',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1成功 0已作废',
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_verify_no` (`verify_no`),
  UNIQUE KEY `uk_order_verify` (`order_id`),
  KEY `idx_verify_time` (`verify_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='核销记录';

-- ---------- 通用表 ----------
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT '登录账号',
  `password` varchar(100) NOT NULL COMMENT 'BCrypt 密码',
  `real_name` varchar(50) NOT NULL COMMENT '姓名',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `avatar` varchar(200) DEFAULT NULL COMMENT '头像相对路径',
  `email` varchar(100) DEFAULT NULL,
  `dept_name` varchar(60) DEFAULT NULL COMMENT '所属组织',
  `credit_score` int DEFAULT 100 COMMENT '信用分',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1启用 0停用',
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE `sys_role` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_name` varchar(50) NOT NULL,
  `role_code` varchar(50) NOT NULL,
  `data_scope` varchar(20) NOT NULL DEFAULT 'SELF' COMMENT 'SELF/DEPT/ALL',
  `sort_no` int DEFAULT 0,
  `status` tinyint NOT NULL DEFAULT 1,
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色表';

CREATE TABLE `sys_user_role` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `role_id` bigint NOT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_role` (`user_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色表';

CREATE TABLE `sys_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `parent_id` bigint NOT NULL DEFAULT 0,
  `menu_name` varchar(60) NOT NULL,
  `path` varchar(120) DEFAULT NULL,
  `component` varchar(120) DEFAULT NULL,
  `perms` varchar(100) DEFAULT NULL,
  `icon` varchar(40) DEFAULT NULL,
  `type` char(1) NOT NULL DEFAULT 'M' COMMENT 'M目录 C菜单 B按钮',
  `sort_no` int DEFAULT 0,
  `visible` tinyint NOT NULL DEFAULT 1,
  `status` tinyint NOT NULL DEFAULT 1,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单权限表';

CREATE TABLE `sys_role_menu` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `role_id` bigint NOT NULL,
  `menu_id` bigint NOT NULL,
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_role_menu` (`role_id`, `menu_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单表';

CREATE TABLE `sys_dict_type` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dict_name` varchar(60) NOT NULL,
  `dict_type` varchar(60) NOT NULL,
  `status` tinyint NOT NULL DEFAULT 1,
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dict_type` (`dict_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典类型表';

CREATE TABLE `sys_dict_data` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `dict_type` varchar(60) NOT NULL,
  `dict_label` varchar(60) NOT NULL,
  `dict_value` varchar(60) NOT NULL,
  `sort_no` int DEFAULT 0,
  `status` tinyint NOT NULL DEFAULT 1,
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  KEY `idx_dict_type` (`dict_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典数据表';

CREATE TABLE `sys_file` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file_name` varchar(200) NOT NULL,
  `file_path` varchar(300) NOT NULL,
  `file_size` bigint DEFAULT 0,
  `file_type` varchar(20) DEFAULT NULL,
  `biz_type` varchar(40) DEFAULT NULL,
  `biz_id` bigint DEFAULT NULL,
  `uploader_id` bigint DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='文件表';

CREATE TABLE `sys_notice` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(120) NOT NULL,
  `content` varchar(1000) DEFAULT NULL,
  `publish_time` datetime DEFAULT NULL,
  `status` tinyint NOT NULL DEFAULT 1,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='公告表';

CREATE TABLE `sys_message` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `receiver_id` bigint NOT NULL,
  `title` varchar(120) NOT NULL,
  `content` varchar(500) DEFAULT NULL,
  `biz_type` varchar(30) DEFAULT NULL,
  `biz_id` bigint DEFAULT NULL,
  `read_flag` tinyint NOT NULL DEFAULT 0,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  KEY `idx_receiver` (`receiver_id`, `read_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内消息表';

CREATE TABLE `sys_oper_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `module` varchar(60) NOT NULL,
  `oper_type` varchar(30) NOT NULL,
  `biz_no` varchar(60) DEFAULT NULL,
  `content` varchar(500) DEFAULT NULL,
  `oper_id` bigint DEFAULT NULL,
  `oper_name` varchar(50) DEFAULT NULL,
  `oper_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip` varchar(40) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  KEY `idx_oper_time` (`oper_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='操作日志表';

-- ---------- 创新点：预测规则与计算留痕 ----------
CREATE TABLE `forecast_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `rule_version` int NOT NULL COMMENT '规则版本号',
  `w_history` decimal(5,2) NOT NULL DEFAULT 30.00 COMMENT '历史同段销量权重%',
  `w_course` decimal(5,2) NOT NULL DEFAULT 20.00 COMMENT '课程表标签权重%',
  `w_weather` decimal(5,2) NOT NULL DEFAULT 15.00 COMMENT '天气因素权重%',
  `w_promo` decimal(5,2) NOT NULL DEFAULT 20.00 COMMENT '促销活动权重%',
  `w_turnover` decimal(5,2) NOT NULL DEFAULT 15.00 COMMENT '商品周转权重%',
  `effective_time` datetime NOT NULL COMMENT '生效时间',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1生效 0历史',
  `remark` varchar(200) DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rule_version` (`rule_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预测规则表（创新点：权重可配置，改版留痕）';

CREATE TABLE `forecast_calc` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `calc_no` varchar(40) NOT NULL,
  `point_id` bigint NOT NULL,
  `slot_id` bigint NOT NULL,
  `slot_date` date NOT NULL,
  `start_time` time NOT NULL,
  `suggest_qty` int NOT NULL DEFAULT 0 COMMENT '建议备货量',
  `score` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '高峰评分',
  `level` varchar(2) NOT NULL DEFAULT 'C' COMMENT 'A/B/C/D',
  `confidence` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '置信度%',
  `rule_version` int NOT NULL COMMENT '计算所用规则版本',
  `snapshot_json` varchar(2000) DEFAULT NULL COMMENT '输入快照与各因素得分',
  `calc_time` datetime NOT NULL,
  `manual_qty` int DEFAULT NULL COMMENT '人工修正备货量，原始结果保留',
  `manual_reason` varchar(200) DEFAULT NULL COMMENT '修正原因',
  `manual_flag` tinyint NOT NULL DEFAULT 0 COMMENT '1已人工修正',
  `manual_by` varchar(50) DEFAULT NULL,
  `manual_time` datetime DEFAULT NULL,
  `create_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `update_by` bigint DEFAULT NULL COMMENT '关联 sys_user.id',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时自动刷新',
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0正常 1删除，查询默认过滤',
  `version` int NOT NULL DEFAULT 0 COMMENT '乐观锁，更新时校验并加1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_calc_no` (`calc_no`),
  KEY `idx_slot_date` (`slot_id`, `slot_date`, `rule_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预测计算留痕表';

-- ---------- 角色 ----------
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(1,'系统管理员','admin','ALL',1,1,'系统管理员角色',NOW());
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(2,'超市运营','operator','ALL',2,1,'超市运营角色',NOW());
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(3,'门店店长','manager','DEPT',3,1,'门店店长角色',NOW());
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(4,'自提点店员','clerk','DEPT',4,1,'自提点店员角色',NOW());
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(5,'备货员','picker','SELF',5,1,'备货员角色',NOW());
INSERT INTO sys_role(id,role_name,role_code,data_scope,sort_no,status,remark,create_time) VALUES(6,'学生','student','SELF',6,1,'学生角色',NOW());
-- ---------- 用户（默认密码均为 123456） ----------
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(1,'admin','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','系统管理员','13800000001','/uploads/seed/avatar/02.jpg','admin@campus.edu.cn','信息中心',100,1,'2026-04-19 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(1,1);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(2,'operator','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','周运营','13800000002','/uploads/seed/avatar/03.jpg','operator@campus.edu.cn','超市运营部',100,1,'2026-04-22 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(2,2);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(3,'operator2','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','孙运营','13800000003','/uploads/seed/avatar/04.jpg','operator2@campus.edu.cn','超市运营部',100,1,'2026-04-25 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(3,2);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(4,'manager','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','刘店长','13800000004','/uploads/seed/avatar/05.jpg','manager@campus.edu.cn','一食堂门店',100,1,'2026-04-28 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(4,3);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(5,'manager2','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','钱店长','13800000005','/uploads/seed/avatar/06.jpg','manager2@campus.edu.cn','南区门店',100,1,'2026-05-01 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(5,3);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(6,'clerk','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','李慧','13800000006','/uploads/seed/avatar/07.jpg','clerk@campus.edu.cn','一食堂自提点',100,1,'2026-05-04 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(6,4);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(7,'clerk2','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','王强','13800000007','/uploads/seed/avatar/08.jpg','clerk2@campus.edu.cn','三号楼自提点',100,1,'2026-05-07 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(7,4);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(8,'picker','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','张拣货','13800000008','/uploads/seed/avatar/01.jpg','picker@campus.edu.cn','一食堂门店',100,1,'2026-05-10 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(8,5);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(9,'picker2','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','吴拣货','13800000009','/uploads/seed/avatar/02.jpg','picker2@campus.edu.cn','南区门店',100,1,'2026-05-13 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(9,5);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(10,'student','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','林小满','13800000010','/uploads/seed/avatar/03.jpg','student@campus.edu.cn','计算机学院',100,1,'2026-05-16 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(10,6);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(11,'student2','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','何思远','13800000011','/uploads/seed/avatar/04.jpg','student2@campus.edu.cn','外国语学院',100,1,'2026-05-19 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(11,6);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(12,'student3','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','郑一鸣','13800000012','/uploads/seed/avatar/05.jpg','student3@campus.edu.cn','机械工程学院',100,1,'2026-05-22 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(12,6);
INSERT INTO sys_user(id,username,password,real_name,phone,avatar,email,dept_name,credit_score,status,create_time) VALUES(13,'student4','$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi','许清','13800000013','/uploads/seed/avatar/06.jpg','student4@campus.edu.cn','经济管理学院',100,1,'2026-05-25 11:14:37');
INSERT INTO sys_user_role(user_id,role_id) VALUES(13,6);
-- ---------- 菜单与角色授权 ----------
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(1,0,'经营看板','/dashboard','Dashboard','dashboard:view','DataBoard','C',1,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(2,0,'商品管理','/goods','GoodsList','goods:list','Goods','C',2,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(3,0,'自提点管理','/point','PointList','point:list','Location','C',5,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(4,0,'时段配置','/slot','SlotList','slot:list','Clock','C',6,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(5,0,'订单管理','/order','OrderList','order:list','List','C',3,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(6,0,'备货工作台','/picking','PickingDesk','picking:task','Box','C',4,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(7,0,'核销台','/verify','VerifyDesk','verify:scan','CircleCheck','C',7,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(8,0,'缺货替换','/replace','ReplaceList','replace:list','Switch','C',8,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(9,0,'预测看板','/forecast','ForecastBoard','forecast:view','TrendCharts','C',9,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(10,0,'系统管理','/system',NULL,NULL,'Setting','M',99,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(11,10,'用户管理','/system/user','SysUser','system:user',NULL,'C',991,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(12,10,'角色管理','/system/role','SysRole','system:role',NULL,'C',992,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(13,10,'菜单管理','/system/menu','SysMenu','system:menu',NULL,'C',993,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(14,10,'字典管理','/system/dict','SysDict','system:dict',NULL,'C',994,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(15,10,'操作日志','/system/log','SysLog','system:log',NULL,'C',995,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(16,0,'我的订单','/my-orders','MyOrders','order:mine','Tickets','C',11,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(17,0,'个人中心','/profile','Profile','profile:view','User','C',20,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(101,2,'商品新增',NULL,NULL,'goods:add',NULL,'B',21,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(102,2,'商品编辑',NULL,NULL,'goods:edit',NULL,'B',22,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(103,3,'自提点新增',NULL,NULL,'point:add',NULL,'B',51,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(104,4,'时段新增',NULL,NULL,'slot:add',NULL,'B',61,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(105,5,'订单取消',NULL,NULL,'order:cancel',NULL,'B',31,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(106,6,'领取任务',NULL,NULL,'picking:claim',NULL,'B',41,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(107,6,'完成备货',NULL,NULL,'picking:finish',NULL,'B',42,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(108,8,'发起替换',NULL,NULL,'replace:add',NULL,'B',81,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(109,9,'规则配置',NULL,NULL,'forecast:rule',NULL,'B',91,1,1);
INSERT INTO sys_menu(id,parent_id,menu_name,path,component,perms,icon,type,sort_no,visible,status) VALUES(110,9,'人工修正',NULL,NULL,'forecast:adjust',NULL,'B',92,1,1);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,1);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,2);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,3);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,4);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,5);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,6);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,7);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,8);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,9);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,10);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,11);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,12);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,13);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,14);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,15);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,16);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,17);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,101);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,102);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,103);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,104);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,105);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,106);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,107);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,108);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,109);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(1,110);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,1);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,2);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,5);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,8);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,9);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,10);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,13);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,14);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,15);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,17);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,101);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,102);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,105);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,108);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,109);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(2,110);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,1);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,2);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,3);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,4);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,5);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,6);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,7);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,8);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,9);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,17);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,101);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,102);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,103);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,104);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,105);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,106);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,107);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,108);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,109);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(3,110);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,1);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,2);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,5);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,7);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,17);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,105);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(4,102);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(5,6);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(5,7);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(5,17);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(5,106);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(5,107);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(6,16);
INSERT INTO sys_role_menu(role_id,menu_id) VALUES(6,17);
-- ---------- 字典 ----------
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(1,'订单状态','order_status',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','待备货','待备货',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','备货中','备货中',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','待自提','待自提',3,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','已核销','已核销',4,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','已取消','已取消',5,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('order_status','超时作废','超时作废',6,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(2,'商品状态','goods_status',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('goods_status','在售','1',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('goods_status','已下架','0',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('goods_status','已售罄','2',3,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(3,'商品分类','category',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','饮料','饮料',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','零食','零食',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','文具','文具',3,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','日用品','日用品',4,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','生鲜','生鲜',5,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('category','面包','面包',6,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(4,'备货任务状态','task_status',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('task_status','待领取','待领取',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('task_status','备货中','备货中',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('task_status','已完成','已完成',3,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('task_status','已挂起','已挂起',4,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(5,'替换单状态','replace_status',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('replace_status','待确认','待确认',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('replace_status','已接受','已接受',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('replace_status','已拒绝','已拒绝',3,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('replace_status','已退款','已退款',4,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(6,'高峰等级','forecast_level',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('forecast_level','A 极高','A',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('forecast_level','B 高峰','B',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('forecast_level','C 平峰','C',3,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('forecast_level','D 低谷','D',4,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(7,'核销方式','verify_type',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('verify_type','扫码','扫码',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('verify_type','取货码','取货码',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('verify_type','人工补录','人工补录',3,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(8,'天气','weather',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('weather','晴天','晴',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('weather','雨天','雨',2,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('weather','高温','高温',3,1,NOW());
INSERT INTO sys_dict_type(id,dict_name,dict_type,status,remark,create_time) VALUES(9,'是否冷藏','cold_flag',1,'业务枚举',NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('cold_flag','冷藏','1',1,1,NOW());
INSERT INTO sys_dict_data(dict_type,dict_label,dict_value,sort_no,status,create_time) VALUES('cold_flag','常温','0',2,1,NOW());
-- ---------- 自提点 ----------
INSERT INTO pickup_point(id,point_no,name,location_desc,open_time,close_time,contact_name,contact_phone,serve_limit,status,image,create_time) VALUES(1,'ZD001','一食堂便利店自提台','第一食堂一层东侧门口，靠近餐盘回收处','07:00:00','22:30:00','李慧','13800010001',8,1,'/uploads/seed/point/01.jpg','2026-05-11 11:14:37');
INSERT INTO pickup_point(id,point_no,name,location_desc,open_time,close_time,contact_name,contact_phone,serve_limit,status,image,create_time) VALUES(2,'ZD002','三号教学楼自助取货柜','三号教学楼 A 座一层大厅，快递柜旁','07:00:00','22:30:00','王强','13800010002',5,1,'/uploads/seed/point/02.jpg','2026-05-16 11:14:37');
INSERT INTO pickup_point(id,point_no,name,location_desc,open_time,close_time,contact_name,contact_phone,serve_limit,status,image,create_time) VALUES(3,'ZD003','图书馆北门便利店','图书馆北门一层，刷卡闸机右手边','07:00:00','22:30:00','陈敏','13800010003',6,1,'/uploads/seed/point/03.jpg','2026-05-21 11:14:37');
INSERT INTO pickup_point(id,point_no,name,location_desc,open_time,close_time,contact_name,contact_phone,serve_limit,status,image,create_time) VALUES(4,'ZD004','南区宿舍生活超市','南区 7 号楼一层架空层，洗衣房对面','07:00:00','22:30:00','赵磊','13800010004',4,1,'/uploads/seed/point/04.jpg','2026-05-26 11:14:37');
-- ---------- 商品（34 条，覆盖 6 分类与 3 状态） ----------
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(1,'CS2605150001','农夫山泉饮用水 550ml','饮料','550ml',2.00,240,0,'A-01-1',0,1,'/uploads/seed/goods/01.jpg','2026-05-15 10:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(2,'CS2605190002','可口可乐 500ml','饮料','500ml',3.00,180,4,'A-01-2',0,1,'/uploads/seed/goods/02.jpg','2026-05-19 09:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(3,'CS2605230003','维他柠檬茶 250ml','饮料','250ml',3.50,96,4,'A-01-3',0,1,'/uploads/seed/goods/03.jpg','2026-05-23 08:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(4,'CS2605270004','蒙牛纯牛奶 250ml','饮料','250ml',3.20,120,6,'A-02-1',1,1,'/uploads/seed/goods/04.jpg','2026-05-27 07:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(5,'CS2605310005','元气森林气泡水 480ml','饮料','480ml',5.00,64,2,'A-02-2',1,1,'/uploads/seed/goods/05.jpg','2026-05-31 06:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(6,'CS2606040006','雀巢咖啡即饮 268ml','饮料','268ml',6.50,48,2,'A-02-3',1,1,'/uploads/seed/goods/06.jpg','2026-06-04 05:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(7,'CS2606080007','康师傅冰红茶 500ml','饮料','500ml',3.00,150,0,'A-01-4',0,1,'/uploads/seed/goods/07.jpg','2026-06-08 04:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(8,'CS2606120008','怡宝纯净水 555ml','饮料','555ml',1.80,200,0,'A-01-5',0,1,'/uploads/seed/goods/01.jpg','2026-06-12 03:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(9,'CS2606160009','乐事薯片原味 70g','零食','70g',6.50,80,3,'B-01-1',0,1,'/uploads/seed/goods/08.jpg','2026-06-16 02:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(10,'CS2606200010','奥利奥饼干 116g','零食','116g',8.50,60,2,'B-01-2',0,1,'/uploads/seed/goods/09.jpg','2026-06-20 01:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(11,'CS2606240011','上好佳鲜虾片 40g','零食','40g',3.00,90,0,'B-01-3',0,0,'/uploads/seed/goods/10.jpg','2026-06-24 00:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(12,'CS2606280012','德芙巧克力 43g','零食','43g',9.90,45,2,'B-02-1',0,1,'/uploads/seed/goods/11.jpg','2026-06-28 11:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(13,'CS2607020013','卫龙辣条 106g','零食','106g',5.50,70,3,'B-02-2',0,2,'/uploads/seed/goods/12.jpg','2026-07-02 10:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(14,'CS2607060014','三只松鼠每日坚果 25g','零食','25g',4.50,55,4,'B-02-3',0,1,'/uploads/seed/goods/13.jpg','2026-07-06 09:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(15,'CS2607100015','好丽友派 6枚装','零食','6枚',12.00,32,2,'B-03-1',0,1,'/uploads/seed/goods/14.jpg','2026-07-10 08:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(16,'CS2607140016','桃李吐司面包 400g','面包','400g',8.00,40,2,'C-01-1',0,1,'/uploads/seed/goods/15.jpg','2026-07-14 07:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(17,'CS2607180017','达利园法式软面包 200g','面包','200g',5.50,48,3,'C-01-2',0,1,'/uploads/seed/goods/16.jpg','2026-07-18 06:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(18,'CS2607220018','现烤起酥牛角包 2只','面包','2只',7.00,24,2,'C-01-3',0,1,'/uploads/seed/goods/19.jpg','2026-07-22 05:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(19,'CS2607260019','曼可顿全麦面包 350g','面包','350g',9.50,26,2,'C-01-4',0,1,'/uploads/seed/goods/20.jpg','2026-07-26 04:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(20,'CS2607300020','晨光中性笔 0.5mm','文具','0.5mm',2.50,120,10,'D-01-1',0,1,'/uploads/seed/goods/17.jpg','2026-07-30 03:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(21,'CS2608030021','A5横线笔记本 80页','文具','80页',6.00,70,5,'D-01-2',0,1,'/uploads/seed/goods/17.jpg','2026-08-03 02:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(22,'CS2608070022','得力订书机 12号','文具','12号',13.00,30,2,'D-01-3',0,0,'/uploads/seed/goods/17.jpg','2026-08-07 01:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(23,'CS2608110023','考试专用2B铅笔 5支','文具','5支',5.00,88,6,'D-02-1',0,1,'/uploads/seed/goods/17.jpg','2026-08-11 00:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(24,'CS2608150024','荧光标记笔 4色','文具','4色',9.00,42,2,'D-02-2',0,1,'/uploads/seed/goods/17.jpg','2026-08-15 11:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(25,'CS2608190025','抽纸 3层100抽','日用品','100抽',4.50,130,5,'E-01-1',0,1,'/uploads/seed/goods/18.jpg','2026-08-19 10:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(26,'CS2608230026','洗发水旅行装 100ml','日用品','100ml',12.50,36,2,'E-01-2',0,2,'/uploads/seed/goods/18.jpg','2026-08-23 09:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(27,'CS2608270027','一次性口罩 10只','日用品','10只',6.00,80,4,'E-01-3',0,1,'/uploads/seed/goods/18.jpg','2026-08-27 08:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(28,'CS2608310028','洗手液 300ml','日用品','300ml',11.00,40,2,'E-02-1',0,1,'/uploads/seed/goods/18.jpg','2026-08-31 07:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(29,'CS2609040029','电池 5号4粒','日用品','4粒',10.00,28,2,'E-02-2',0,1,'/uploads/seed/goods/18.jpg','2026-09-04 06:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(30,'CS2609080030','香蕉 约500g','生鲜','500g',6.80,30,2,'F-01-1',1,1,'/uploads/seed/goods/16.jpg','2026-09-08 05:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(31,'CS2609120031','苹果 约500g','生鲜','500g',8.50,26,2,'F-01-2',1,1,'/uploads/seed/goods/19.jpg','2026-09-12 04:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(32,'CS2609160032','小番茄 250g','生鲜','250g',7.50,18,2,'F-01-3',1,1,'/uploads/seed/goods/20.jpg','2026-09-16 03:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(33,'CS2609200033','酸奶杯 180g','生鲜','180g',4.80,36,3,'F-02-1',1,0,'/uploads/seed/goods/04.jpg','2026-09-20 02:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(34,'CS2609240034','三明治火腿 2片装','生鲜','2片',5.20,20,2,'F-02-2',1,1,'/uploads/seed/goods/15.jpg','2026-09-24 01:14:37');
INSERT INTO shop_goods(id,goods_no,name,category_code,spec,sale_price,stock_qty,limit_qty,shelf_code,is_cold,status,image,create_time) VALUES(35,'CS2609280035','卤蛋 2只装','生鲜','2只',3.60,44,4,'F-02-3',1,1,'/uploads/seed/goods/12.jpg','2026-09-28 00:14:37');
-- ---------- 自提时段（未来 7 天，每点每天 6 段） ----------
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(1,'SD261102010',1,'2026-11-02','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(2,'SD261102011',1,'2026-11-02','09:30:00','11:00:00',34,34,2,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(3,'SD261102012',1,'2026-11-02','11:00:00','12:30:00',37,4,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(4,'SD261102013',1,'2026-11-02','12:30:00','14:00:00',40,6,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(5,'SD261102014',1,'2026-11-02','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(6,'SD261102015',1,'2026-11-02','18:30:00','20:00:00',26,2,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(7,'SD261102020',2,'2026-11-02','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(8,'SD261102021',2,'2026-11-02','09:30:00','11:00:00',41,41,2,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(9,'SD261102022',2,'2026-11-02','11:00:00','12:30:00',24,4,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(10,'SD261102023',2,'2026-11-02','12:30:00','14:00:00',27,6,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(11,'SD261102024',2,'2026-11-02','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(12,'SD261102025',2,'2026-11-02','18:30:00','20:00:00',33,2,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(13,'SD261102030',3,'2026-11-02','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(14,'SD261102031',3,'2026-11-02','09:30:00','11:00:00',28,28,2,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(15,'SD261102032',3,'2026-11-02','11:00:00','12:30:00',31,4,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(16,'SD261102033',3,'2026-11-02','12:30:00','14:00:00',34,6,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(17,'SD261102034',3,'2026-11-02','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(18,'SD261102035',3,'2026-11-02','18:30:00','20:00:00',40,2,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(19,'SD261102040',4,'2026-11-02','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(20,'SD261102041',4,'2026-11-02','09:30:00','11:00:00',35,35,2,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(21,'SD261102042',4,'2026-11-02','11:00:00','12:30:00',38,4,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(22,'SD261102043',4,'2026-11-02','12:30:00','14:00:00',41,6,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(23,'SD261102044',4,'2026-11-02','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(24,'SD261102045',4,'2026-11-02','18:30:00','20:00:00',27,2,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(25,'SD261103010',1,'2026-11-03','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(26,'SD261103011',1,'2026-11-03','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(27,'SD261103012',1,'2026-11-03','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(28,'SD261103013',1,'2026-11-03','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(29,'SD261103014',1,'2026-11-03','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(30,'SD261103015',1,'2026-11-03','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(31,'SD261103020',2,'2026-11-03','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(32,'SD261103021',2,'2026-11-03','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(33,'SD261103022',2,'2026-11-03','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(34,'SD261103023',2,'2026-11-03','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(35,'SD261103024',2,'2026-11-03','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(36,'SD261103025',2,'2026-11-03','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(37,'SD261103030',3,'2026-11-03','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(38,'SD261103031',3,'2026-11-03','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(39,'SD261103032',3,'2026-11-03','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(40,'SD261103033',3,'2026-11-03','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(41,'SD261103034',3,'2026-11-03','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(42,'SD261103035',3,'2026-11-03','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(43,'SD261103040',4,'2026-11-03','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(44,'SD261103041',4,'2026-11-03','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(45,'SD261103042',4,'2026-11-03','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(46,'SD261103043',4,'2026-11-03','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(47,'SD261103044',4,'2026-11-03','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(48,'SD261103045',4,'2026-11-03','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(49,'SD261104010',1,'2026-11-04','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(50,'SD261104011',1,'2026-11-04','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(51,'SD261104012',1,'2026-11-04','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(52,'SD261104013',1,'2026-11-04','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(53,'SD261104014',1,'2026-11-04','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(54,'SD261104015',1,'2026-11-04','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(55,'SD261104020',2,'2026-11-04','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(56,'SD261104021',2,'2026-11-04','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(57,'SD261104022',2,'2026-11-04','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(58,'SD261104023',2,'2026-11-04','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(59,'SD261104024',2,'2026-11-04','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(60,'SD261104025',2,'2026-11-04','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(61,'SD261104030',3,'2026-11-04','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(62,'SD261104031',3,'2026-11-04','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(63,'SD261104032',3,'2026-11-04','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(64,'SD261104033',3,'2026-11-04','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(65,'SD261104034',3,'2026-11-04','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(66,'SD261104035',3,'2026-11-04','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(67,'SD261104040',4,'2026-11-04','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(68,'SD261104041',4,'2026-11-04','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(69,'SD261104042',4,'2026-11-04','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(70,'SD261104043',4,'2026-11-04','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(71,'SD261104044',4,'2026-11-04','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(72,'SD261104045',4,'2026-11-04','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(73,'SD261105010',1,'2026-11-05','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(74,'SD261105011',1,'2026-11-05','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(75,'SD261105012',1,'2026-11-05','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(76,'SD261105013',1,'2026-11-05','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(77,'SD261105014',1,'2026-11-05','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(78,'SD261105015',1,'2026-11-05','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(79,'SD261105020',2,'2026-11-05','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(80,'SD261105021',2,'2026-11-05','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(81,'SD261105022',2,'2026-11-05','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(82,'SD261105023',2,'2026-11-05','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(83,'SD261105024',2,'2026-11-05','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(84,'SD261105025',2,'2026-11-05','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(85,'SD261105030',3,'2026-11-05','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(86,'SD261105031',3,'2026-11-05','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(87,'SD261105032',3,'2026-11-05','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(88,'SD261105033',3,'2026-11-05','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(89,'SD261105034',3,'2026-11-05','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(90,'SD261105035',3,'2026-11-05','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(91,'SD261105040',4,'2026-11-05','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(92,'SD261105041',4,'2026-11-05','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(93,'SD261105042',4,'2026-11-05','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(94,'SD261105043',4,'2026-11-05','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(95,'SD261105044',4,'2026-11-05','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(96,'SD261105045',4,'2026-11-05','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(97,'SD261106010',1,'2026-11-06','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(98,'SD261106011',1,'2026-11-06','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(99,'SD261106012',1,'2026-11-06','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(100,'SD261106013',1,'2026-11-06','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(101,'SD261106014',1,'2026-11-06','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(102,'SD261106015',1,'2026-11-06','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(103,'SD261106020',2,'2026-11-06','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(104,'SD261106021',2,'2026-11-06','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(105,'SD261106022',2,'2026-11-06','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(106,'SD261106023',2,'2026-11-06','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(107,'SD261106024',2,'2026-11-06','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(108,'SD261106025',2,'2026-11-06','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(109,'SD261106030',3,'2026-11-06','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(110,'SD261106031',3,'2026-11-06','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(111,'SD261106032',3,'2026-11-06','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(112,'SD261106033',3,'2026-11-06','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(113,'SD261106034',3,'2026-11-06','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(114,'SD261106035',3,'2026-11-06','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(115,'SD261106040',4,'2026-11-06','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(116,'SD261106041',4,'2026-11-06','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(117,'SD261106042',4,'2026-11-06','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(118,'SD261106043',4,'2026-11-06','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(119,'SD261106044',4,'2026-11-06','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(120,'SD261106045',4,'2026-11-06','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(121,'SD261107010',1,'2026-11-07','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(122,'SD261107011',1,'2026-11-07','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(123,'SD261107012',1,'2026-11-07','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(124,'SD261107013',1,'2026-11-07','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(125,'SD261107014',1,'2026-11-07','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(126,'SD261107015',1,'2026-11-07','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(127,'SD261107020',2,'2026-11-07','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(128,'SD261107021',2,'2026-11-07','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(129,'SD261107022',2,'2026-11-07','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(130,'SD261107023',2,'2026-11-07','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(131,'SD261107024',2,'2026-11-07','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(132,'SD261107025',2,'2026-11-07','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(133,'SD261107030',3,'2026-11-07','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(134,'SD261107031',3,'2026-11-07','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(135,'SD261107032',3,'2026-11-07','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(136,'SD261107033',3,'2026-11-07','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(137,'SD261107034',3,'2026-11-07','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(138,'SD261107035',3,'2026-11-07','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(139,'SD261107040',4,'2026-11-07','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(140,'SD261107041',4,'2026-11-07','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(141,'SD261107042',4,'2026-11-07','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(142,'SD261107043',4,'2026-11-07','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(143,'SD261107044',4,'2026-11-07','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(144,'SD261107045',4,'2026-11-07','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(145,'SD261108010',1,'2026-11-08','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(146,'SD261108011',1,'2026-11-08','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(147,'SD261108012',1,'2026-11-08','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(148,'SD261108013',1,'2026-11-08','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(149,'SD261108014',1,'2026-11-08','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(150,'SD261108015',1,'2026-11-08','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(151,'SD261108020',2,'2026-11-08','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(152,'SD261108021',2,'2026-11-08','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(153,'SD261108022',2,'2026-11-08','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(154,'SD261108023',2,'2026-11-08','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(155,'SD261108024',2,'2026-11-08','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(156,'SD261108025',2,'2026-11-08','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(157,'SD261108030',3,'2026-11-08','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(158,'SD261108031',3,'2026-11-08','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(159,'SD261108032',3,'2026-11-08','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(160,'SD261108033',3,'2026-11-08','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(161,'SD261108034',3,'2026-11-08','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(162,'SD261108035',3,'2026-11-08','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(163,'SD261108040',4,'2026-11-08','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(164,'SD261108041',4,'2026-11-08','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(165,'SD261108042',4,'2026-11-08','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(166,'SD261108043',4,'2026-11-08','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(167,'SD261108044',4,'2026-11-08','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(168,'SD261108045',4,'2026-11-08','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(169,'SD261109010',1,'2026-11-09','08:00:00','09:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(170,'SD261109011',1,'2026-11-09','09:30:00','11:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(171,'SD261109012',1,'2026-11-09','11:00:00','12:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(172,'SD261109013',1,'2026-11-09','12:30:00','14:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(173,'SD261109014',1,'2026-11-09','17:00:00','18:30:00',43,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(174,'SD261109015',1,'2026-11-09','18:30:00','20:00:00',26,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(175,'SD261109020',2,'2026-11-09','08:00:00','09:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(176,'SD261109021',2,'2026-11-09','09:30:00','11:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(177,'SD261109022',2,'2026-11-09','11:00:00','12:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(178,'SD261109023',2,'2026-11-09','12:30:00','14:00:00',27,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(179,'SD261109024',2,'2026-11-09','17:00:00','18:30:00',30,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(180,'SD261109025',2,'2026-11-09','18:30:00','20:00:00',33,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(181,'SD261109030',3,'2026-11-09','08:00:00','09:30:00',25,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(182,'SD261109031',3,'2026-11-09','09:30:00','11:00:00',28,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(183,'SD261109032',3,'2026-11-09','11:00:00','12:30:00',31,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(184,'SD261109033',3,'2026-11-09','12:30:00','14:00:00',34,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(185,'SD261109034',3,'2026-11-09','17:00:00','18:30:00',37,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(186,'SD261109035',3,'2026-11-09','18:30:00','20:00:00',40,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(187,'SD261109040',4,'2026-11-09','08:00:00','09:30:00',32,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(188,'SD261109041',4,'2026-11-09','09:30:00','11:00:00',35,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(189,'SD261109042',4,'2026-11-09','11:00:00','12:30:00',38,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(190,'SD261109043',4,'2026-11-09','12:30:00','14:00:00',41,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(191,'SD261109044',4,'2026-11-09','17:00:00','18:30:00',24,0,1,'2026-11-01 11:14:37');
INSERT INTO pick_slot(id,slot_no,point_id,slot_date,start_time,end_time,capacity,booked_count,status,create_time) VALUES(192,'SD261109045',4,'2026-11-09','18:30:00','20:00:00',27,0,1,'2026-11-01 11:14:37');
-- ---------- 自提订单（52 条，覆盖 6 状态，时间分散近 6 个月） ----------
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(1,'ZT26110100001',10,1,1,5.60,5.60,'100007','2026-11-01 07:00:00','2026-11-01 07:06:00',NULL,'已核销',10,'2026-11-01 07:00:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100010',1,1,1,2.00,2.00,0,1,'2026-11-01 07:00:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100011',1,8,2,1.80,3.60,0,1,'2026-11-01 07:00:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611010001',1,'张拣货','A-01-1,A-01-5',3,3,'2026-11-01 07:02:00','2026-11-01 07:06:00','已完成','2026-11-01 07:00:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2611010001',1,'100007','李慧','2026-11-01 07:26:00','扫码',1,7,'2026-11-01 07:26:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(2,'ZT26103100002',11,2,8,22.40,22.40,'100144','2026-10-31 08:07:00','2026-10-31 08:14:00',NULL,'已核销',11,'2026-10-31 08:07:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100020',2,4,2,3.20,6.40,0,1,'2026-10-31 08:07:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100021',2,11,3,3.00,9.00,0,1,'2026-10-31 08:07:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100022',2,18,1,7.00,7.00,0,1,'2026-10-31 08:07:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610310002',2,'吴拣货','A-02-1,B-01-3,C-01-3',6,6,'2026-10-31 08:09:00','2026-10-31 08:14:00','已完成','2026-10-31 08:07:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610310002',2,'100144','王强','2026-10-31 08:35:00','取货码',1,6,'2026-10-31 08:35:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(3,'ZT26103000003',12,3,15,58.50,58.50,'100281','2026-10-30 09:14:00','2026-10-30 09:22:00',NULL,'已核销',12,'2026-10-30 09:14:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000030',3,7,3,3.00,9.00,0,1,'2026-10-30 09:14:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000031',3,14,1,4.50,4.50,0,1,'2026-10-30 09:14:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000032',3,21,2,6.00,12.00,0,1,'2026-10-30 09:14:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000033',3,28,3,11.00,33.00,0,1,'2026-10-30 09:14:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610300003',3,'张拣货','A-01-4,B-02-3,D-01-2,E-02-1',9,9,'2026-10-30 09:16:00','2026-10-30 09:22:00','已完成','2026-10-30 09:14:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610300003',3,'100281','陈敏','2026-10-30 09:44:00','人工补录',1,7,'2026-10-30 09:44:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(4,'ZT26102800004',13,4,22,19.50,19.50,'100418','2026-10-28 10:21:00','2026-10-28 10:30:00',NULL,'已核销',13,'2026-10-28 10:21:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800040',4,10,1,8.50,8.50,0,1,'2026-10-28 10:21:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800041',4,17,2,5.50,11.00,0,1,'2026-10-28 10:21:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610280004',4,'吴拣货','B-01-2,C-01-2',3,3,'2026-10-28 10:23:00','2026-10-28 10:30:00','已完成','2026-10-28 10:21:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610280004',4,'100418','赵磊','2026-10-28 10:53:00','扫码',1,6,'2026-10-28 10:53:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(5,'ZT26102500005',10,1,1,24.50,24.50,'100555','2026-10-25 11:28:00','2026-10-25 11:38:00',NULL,'已核销',10,'2026-10-25 11:28:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500050',5,13,2,5.50,11.00,0,1,'2026-10-25 11:28:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500051',5,20,3,2.50,7.50,0,1,'2026-10-25 11:28:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500052',5,27,1,6.00,6.00,0,1,'2026-10-25 11:28:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610250005',5,'张拣货','B-02-2,D-01-1,E-01-3',6,6,'2026-10-25 11:30:00','2026-10-25 11:38:00','已完成','2026-10-25 11:28:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610250005',5,'100555','李慧','2026-10-25 12:02:00','取货码',1,7,'2026-10-25 12:02:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(6,'ZT26102100006',11,2,8,53.10,53.10,'100692','2026-10-21 12:35:00','2026-10-21 12:46:00',NULL,'已核销',11,'2026-10-21 12:35:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100060',6,16,3,8.00,24.00,0,1,'2026-10-21 12:35:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100061',6,23,1,5.00,5.00,0,1,'2026-10-21 12:35:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100062',6,30,2,6.80,13.60,0,1,'2026-10-21 12:35:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100063',6,3,3,3.50,10.50,0,1,'2026-10-21 12:35:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610210006',6,'吴拣货','A-01-3,C-01-1,D-02-1,F-01-1',9,9,'2026-10-21 12:37:00','2026-10-21 12:46:00','已完成','2026-10-21 12:35:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610210006',6,'100692','王强','2026-10-21 13:11:00','人工补录',1,6,'2026-10-21 13:11:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(7,'ZT26101500007',12,3,15,34.50,34.50,'100829','2026-10-15 13:42:00','2026-10-15 13:54:00',NULL,'已核销',12,'2026-10-15 13:42:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26101500070',7,19,1,9.50,9.50,0,1,'2026-10-15 13:42:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26101500071',7,26,2,12.50,25.00,0,1,'2026-10-15 13:42:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610150007',7,'张拣货','C-01-4,E-01-2',3,3,'2026-10-15 13:44:00','2026-10-15 13:54:00','已完成','2026-10-15 13:42:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610150007',7,'100829','陈敏','2026-10-15 14:20:00','扫码',1,7,'2026-10-15 14:20:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(8,'ZT26100800008',13,4,22,59.00,59.00,'100966','2026-10-08 14:49:00','2026-10-08 15:02:00',NULL,'已核销',13,'2026-10-08 14:49:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800080',8,22,2,13.00,26.00,0,1,'2026-10-08 14:49:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800081',8,29,3,10.00,30.00,0,1,'2026-10-08 14:49:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800082',8,2,1,3.00,3.00,0,1,'2026-10-08 14:49:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610080008',8,'吴拣货','A-01-2,D-01-3,E-02-2',6,6,'2026-10-08 14:51:00','2026-10-08 15:02:00','已完成','2026-10-08 14:49:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610080008',8,'100966','赵磊','2026-10-08 15:29:00','取货码',1,6,'2026-10-08 15:29:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(9,'ZT26093000009',10,1,1,60.70,60.70,'101103','2026-09-30 15:56:00','2026-09-30 16:10:00',NULL,'已核销',10,'2026-09-30 15:56:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000090',9,25,3,4.50,13.50,0,1,'2026-09-30 15:56:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000091',9,32,1,7.50,7.50,0,1,'2026-09-30 15:56:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000092',9,5,2,5.00,10.00,0,1,'2026-09-30 15:56:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000093',9,12,3,9.90,29.70,0,1,'2026-09-30 15:56:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609300009',9,'张拣货','A-02-2,B-02-1,E-01-1,F-01-3',9,9,'2026-09-30 15:58:00','2026-09-30 16:10:00','已完成','2026-09-30 15:56:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2609300009',9,'101103','李慧','2026-09-30 16:38:00','人工补录',1,7,'2026-09-30 16:38:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(10,'ZT26091500010',11,2,8,15.00,15.00,'101240','2026-09-15 16:03:00','2026-09-15 16:09:00',NULL,'已核销',11,'2026-09-15 16:03:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500100',10,28,1,11.00,11.00,0,1,'2026-09-15 16:03:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500101',10,1,2,2.00,4.00,0,1,'2026-09-15 16:03:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609150010',10,'吴拣货','A-01-1,E-02-1',3,3,'2026-09-15 16:05:00','2026-09-15 16:09:00','已完成','2026-09-15 16:03:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2609150010',10,'101240','王强','2026-09-15 16:38:00','扫码',1,6,'2026-09-15 16:38:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(11,'ZT26090100011',12,3,15,29.60,29.60,'101377','2026-09-01 17:10:00','2026-09-01 17:17:00',NULL,'已核销',12,'2026-09-01 17:10:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26090100110',11,31,2,8.50,17.00,0,1,'2026-09-01 17:10:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26090100111',11,4,3,3.20,9.60,0,1,'2026-09-01 17:10:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26090100112',11,11,1,3.00,3.00,0,1,'2026-09-01 17:10:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609010011',11,'张拣货','A-02-1,B-01-3,F-01-2',6,6,'2026-09-01 17:12:00','2026-09-01 17:17:00','已完成','2026-09-01 17:10:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2609010011',11,'101377','陈敏','2026-09-01 17:47:00','取货码',1,7,'2026-09-01 17:47:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(12,'ZT26081800012',13,4,22,45.60,45.60,'101514','2026-08-18 18:17:00','2026-08-18 18:25:00',NULL,'已核销',13,'2026-08-18 18:17:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800120',12,34,3,5.20,15.60,0,1,'2026-08-18 18:17:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800121',12,7,1,3.00,3.00,0,1,'2026-08-18 18:17:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800122',12,14,2,4.50,9.00,0,1,'2026-08-18 18:17:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800123',12,21,3,6.00,18.00,0,1,'2026-08-18 18:17:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2608180012',12,'吴拣货','A-01-4,B-02-3,D-01-2,F-02-2',9,9,'2026-08-18 18:19:00','2026-08-18 18:25:00','已完成','2026-08-18 18:17:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2608180012',12,'101514','赵磊','2026-08-18 18:56:00','人工补录',1,6,'2026-08-18 18:56:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(13,'ZT26073000013',10,1,1,20.50,20.50,'101651','2026-07-30 19:24:00','2026-07-30 19:33:00',NULL,'已核销',10,'2026-07-30 19:24:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000130',13,3,1,3.50,3.50,0,1,'2026-07-30 19:24:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000131',13,10,2,8.50,17.00,0,1,'2026-07-30 19:24:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2607300013',13,'张拣货','A-01-3,B-01-2',3,3,'2026-07-30 19:26:00','2026-07-30 19:33:00','已完成','2026-07-30 19:24:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2607300013',13,'101651','李慧','2026-07-30 20:05:00','扫码',1,7,'2026-07-30 20:05:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(14,'ZT26070500014',11,2,8,32.00,32.00,'101788','2026-07-05 07:31:00','2026-07-05 07:41:00',NULL,'已核销',11,'2026-07-05 07:31:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26070500140',14,6,2,6.50,13.00,0,1,'2026-07-05 07:31:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26070500141',14,13,3,5.50,16.50,0,1,'2026-07-05 07:31:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26070500142',14,20,1,2.50,2.50,0,1,'2026-07-05 07:31:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2607050014',14,'吴拣货','A-02-3,B-02-2,D-01-1',6,6,'2026-07-05 07:33:00','2026-07-05 07:41:00','已完成','2026-07-05 07:31:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2607050014',14,'101788','王强','2026-07-05 08:14:00','取货码',1,6,'2026-07-05 08:14:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(15,'ZT26060500015',12,3,15,57.90,57.90,'101925','2026-06-05 08:38:00','2026-06-05 08:49:00',NULL,'已核销',12,'2026-06-05 08:38:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500150',15,9,3,6.50,19.50,0,1,'2026-06-05 08:38:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500151',15,16,1,8.00,8.00,0,1,'2026-06-05 08:38:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500152',15,23,2,5.00,10.00,0,1,'2026-06-05 08:38:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500153',15,30,3,6.80,20.40,0,1,'2026-06-05 08:38:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2606050015',15,'张拣货','B-01-1,C-01-1,D-02-1,F-01-1',9,9,'2026-06-05 08:40:00','2026-06-05 08:49:00','已完成','2026-06-05 08:38:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2606050015',15,'101925','陈敏','2026-06-05 09:23:00','人工补录',1,7,'2026-06-05 09:23:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(16,'ZT26051600016',13,4,22,28.90,28.90,'102062','2026-05-16 09:45:00','2026-05-16 09:57:00',NULL,'已核销',13,'2026-05-16 09:45:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600160',16,12,1,9.90,9.90,0,1,'2026-05-16 09:45:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600161',16,19,2,9.50,19.00,0,1,'2026-05-16 09:45:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2605160016',16,'吴拣货','B-02-1,C-01-4',3,3,'2026-05-16 09:47:00','2026-05-16 09:57:00','已完成','2026-05-16 09:45:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2605160016',16,'102062','赵磊','2026-05-16 10:32:00','扫码',1,6,'2026-05-16 10:32:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(17,'ZT26110100017',10,1,1,73.00,73.00,'102199','2026-11-01 10:52:00','2026-11-01 11:05:00',NULL,'已核销',10,'2026-11-01 10:52:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100170',17,15,2,12.00,24.00,0,1,'2026-11-01 10:52:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100171',17,22,3,13.00,39.00,0,1,'2026-11-01 10:52:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100172',17,29,1,10.00,10.00,0,1,'2026-11-01 10:52:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611010017',17,'张拣货','B-03-1,D-01-3,E-02-2',6,6,'2026-11-01 10:54:00','2026-11-01 11:05:00','已完成','2026-11-01 10:52:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2611010017',17,'102199','李慧','2026-11-01 11:41:00','取货码',1,7,'2026-11-01 11:41:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(18,'ZT26103100018',11,2,8,55.50,55.50,'102336','2026-10-31 11:59:00','2026-10-31 12:13:00',NULL,'已核销',11,'2026-10-31 11:59:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100180',18,18,3,7.00,21.00,0,1,'2026-10-31 11:59:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100181',18,25,1,4.50,4.50,0,1,'2026-10-31 11:59:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100182',18,32,2,7.50,15.00,0,1,'2026-10-31 11:59:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100183',18,5,3,5.00,15.00,0,1,'2026-10-31 11:59:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610310018',18,'吴拣货','A-02-2,C-01-3,E-01-1,F-01-3',9,9,'2026-10-31 12:01:00','2026-10-31 12:13:00','已完成','2026-10-31 11:59:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610310018',18,'102336','王强','2026-10-31 12:50:00','人工补录',1,6,'2026-10-31 12:50:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(19,'ZT26103000019',12,3,15,28.00,28.00,'102473','2026-10-30 12:06:00','2026-10-30 12:12:00',NULL,'已核销',12,'2026-10-30 12:06:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000190',19,21,1,6.00,6.00,0,1,'2026-10-30 12:06:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000191',19,28,2,11.00,22.00,0,1,'2026-10-30 12:06:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610300019',19,'张拣货','D-01-2,E-02-1',3,3,'2026-10-30 12:08:00','2026-10-30 12:12:00','已完成','2026-10-30 12:06:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610300019',19,'102473','陈敏','2026-10-30 12:50:00','扫码',1,7,'2026-10-30 12:50:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(20,'ZT26102800020',13,4,22,46.70,46.70,'102610','2026-10-28 13:13:00','2026-10-28 13:20:00',NULL,'已核销',13,'2026-10-28 13:13:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800200',20,24,2,9.00,18.00,0,1,'2026-10-28 13:13:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800201',20,31,3,8.50,25.50,0,1,'2026-10-28 13:13:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800202',20,4,1,3.20,3.20,0,1,'2026-10-28 13:13:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610280020',20,'吴拣货','A-02-1,D-02-2,F-01-2',6,6,'2026-10-28 13:15:00','2026-10-28 13:20:00','已完成','2026-10-28 13:13:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610280020',20,'102610','赵磊','2026-10-28 13:59:00','取货码',1,6,'2026-10-28 13:59:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(21,'ZT26102500021',10,1,1,42.70,42.70,'102747','2026-10-25 14:20:00','2026-10-25 14:28:00',NULL,'已核销',10,'2026-10-25 14:20:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500210',21,27,3,6.00,18.00,0,1,'2026-10-25 14:20:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500211',21,34,1,5.20,5.20,0,1,'2026-10-25 14:20:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500212',21,7,2,3.00,6.00,0,1,'2026-10-25 14:20:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102500213',21,14,3,4.50,13.50,0,1,'2026-10-25 14:20:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610250021',21,'张拣货','A-01-4,B-02-3,E-01-3,F-02-2',9,9,'2026-10-25 14:22:00','2026-10-25 14:28:00','已完成','2026-10-25 14:20:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610250021',21,'102747','李慧','2026-10-25 15:08:00','人工补录',1,7,'2026-10-25 15:08:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(22,'ZT26102100022',11,2,8,13.80,13.80,'102884','2026-10-21 15:27:00','2026-10-21 15:36:00',NULL,'已核销',11,'2026-10-21 15:27:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100220',22,30,1,6.80,6.80,0,1,'2026-10-21 15:27:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102100221',22,3,2,3.50,7.00,0,1,'2026-10-21 15:27:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610210022',22,'吴拣货','A-01-3,F-01-1',3,3,'2026-10-21 15:29:00','2026-10-21 15:36:00','已完成','2026-10-21 15:27:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610210022',22,'102884','王强','2026-10-21 16:17:00','扫码',1,6,'2026-10-21 16:17:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(23,'ZT26101500023',12,3,15,34.60,34.60,'103021','2026-10-15 16:34:00','2026-10-15 16:44:00',NULL,'已核销',12,'2026-10-15 16:34:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26101500230',23,33,2,4.80,9.60,0,1,'2026-10-15 16:34:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26101500231',23,6,3,6.50,19.50,0,1,'2026-10-15 16:34:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26101500232',23,13,1,5.50,5.50,0,1,'2026-10-15 16:34:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610150023',23,'张拣货','A-02-3,B-02-2,F-02-1',6,6,'2026-10-15 16:36:00','2026-10-15 16:44:00','已完成','2026-10-15 16:34:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610150023',23,'103021','陈敏','2026-10-15 17:26:00','取货码',1,7,'2026-10-15 17:26:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(24,'ZT26100800024',13,4,22,46.50,46.50,'103158','2026-10-08 17:41:00','2026-10-08 17:52:00',NULL,'已核销',13,'2026-10-08 17:41:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800240',24,2,3,3.00,9.00,0,1,'2026-10-08 17:41:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800241',24,9,1,6.50,6.50,0,1,'2026-10-08 17:41:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800242',24,16,2,8.00,16.00,0,1,'2026-10-08 17:41:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26100800243',24,23,3,5.00,15.00,0,1,'2026-10-08 17:41:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610080024',24,'吴拣货','A-01-2,B-01-1,C-01-1,D-02-1',9,9,'2026-10-08 17:43:00','2026-10-08 17:52:00','已完成','2026-10-08 17:41:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2610080024',24,'103158','赵磊','2026-10-08 18:35:00','人工补录',1,6,'2026-10-08 18:35:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(25,'ZT26093000025',10,1,1,24.80,24.80,'103295','2026-09-30 18:48:00','2026-09-30 19:00:00',NULL,'已核销',10,'2026-09-30 18:48:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000250',25,5,1,5.00,5.00,0,1,'2026-09-30 18:48:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26093000251',25,12,2,9.90,19.80,0,1,'2026-09-30 18:48:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609300025',25,'张拣货','A-02-2,B-02-1',3,3,'2026-09-30 18:50:00','2026-09-30 19:00:00','已完成','2026-09-30 18:48:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2609300025',25,'103295','李慧','2026-09-30 19:44:00','扫码',1,7,'2026-09-30 19:44:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(26,'ZT26091500026',11,2,8,52.60,52.60,'103432','2026-09-15 19:55:00','2026-09-15 20:08:00',NULL,'已核销',11,'2026-09-15 19:55:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500260',26,8,2,1.80,3.60,0,1,'2026-09-15 19:55:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500261',26,15,3,12.00,36.00,0,1,'2026-09-15 19:55:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500262',26,22,1,13.00,13.00,0,1,'2026-09-15 19:55:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609150026',26,'吴拣货','A-01-5,B-03-1,D-01-3',6,6,'2026-09-15 19:57:00','2026-09-15 20:08:00','已完成','2026-09-15 19:55:00');
INSERT INTO pickup_verify(verify_no,order_id,pickup_code,verifier,verify_time,verify_type,status,create_by,create_time) VALUES('HX2609150026',26,'103432','王强','2026-09-15 20:53:00','取货码',1,6,'2026-09-15 20:53:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(27,'ZT26110200027',12,3,17,47.50,47.50,'103569','2026-11-02 08:12:37','2026-11-02 08:26:37',NULL,'待自提',12,'2026-11-02 08:12:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200270',27,11,3,3.00,9.00,0,1,'2026-11-02 08:12:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200271',27,18,1,7.00,7.00,0,1,'2026-11-02 08:12:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200272',27,25,2,4.50,9.00,0,1,'2026-11-02 08:12:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200273',27,32,3,7.50,22.50,0,1,'2026-11-02 08:12:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020027',27,'张拣货','B-01-3,C-01-3,E-01-1,F-01-3',9,9,'2026-11-02 08:14:37','2026-11-02 08:26:37','已完成','2026-11-02 08:12:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(28,'ZT26110200028',13,4,24,16.50,16.50,'103706','2026-11-02 10:05:37','2026-11-02 10:11:37',NULL,'待自提',13,'2026-11-02 10:05:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200280',28,14,1,4.50,4.50,0,1,'2026-11-02 10:05:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200281',28,21,2,6.00,12.00,0,1,'2026-11-02 10:05:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020028',28,'吴拣货','B-02-3,D-01-2',3,3,'2026-11-02 10:07:37','2026-11-02 10:11:37','已完成','2026-11-02 10:05:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(29,'ZT26110200029',10,1,5,46.50,46.50,'103843','2026-11-02 08:58:37','2026-11-02 09:05:37',NULL,'待自提',10,'2026-11-02 08:58:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200290',29,17,2,5.50,11.00,0,1,'2026-11-02 08:58:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200291',29,24,3,9.00,27.00,0,1,'2026-11-02 08:58:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200292',29,31,1,8.50,8.50,0,1,'2026-11-02 08:58:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020029',29,'张拣货','C-01-2,D-02-2,F-01-2',6,6,'2026-11-02 09:00:37','2026-11-02 09:05:37','已完成','2026-11-02 08:58:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(30,'ZT26110200030',11,2,12,32.90,32.90,'103980','2026-11-02 07:51:37','2026-11-02 07:59:37',NULL,'待自提',11,'2026-11-02 07:51:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200300',30,20,3,2.50,7.50,0,1,'2026-11-02 07:51:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200301',30,27,1,6.00,6.00,0,1,'2026-11-02 07:51:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200302',30,34,2,5.20,10.40,0,1,'2026-11-02 07:51:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200303',30,7,3,3.00,9.00,0,1,'2026-11-02 07:51:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020030',30,'吴拣货','A-01-4,D-01-1,E-01-3,F-02-2',9,9,'2026-11-02 07:53:37','2026-11-02 07:59:37','已完成','2026-11-02 07:51:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(31,'ZT26110200031',12,3,17,18.60,18.60,'104117','2026-11-02 09:44:37','2026-11-02 09:53:37',NULL,'待自提',12,'2026-11-02 09:44:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200310',31,23,1,5.00,5.00,0,1,'2026-11-02 09:44:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200311',31,30,2,6.80,13.60,0,1,'2026-11-02 09:44:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020031',31,'张拣货','D-02-1,F-01-1',3,3,'2026-11-02 09:46:37','2026-11-02 09:53:37','已完成','2026-11-02 09:44:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(32,'ZT26110200032',13,4,24,45.90,45.90,'104254','2026-11-02 08:37:37','2026-11-02 08:47:37',NULL,'待自提',13,'2026-11-02 08:37:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200320',32,26,2,12.50,25.00,0,1,'2026-11-02 08:37:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200321',32,33,3,4.80,14.40,0,1,'2026-11-02 08:37:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200322',32,6,1,6.50,6.50,0,1,'2026-11-02 08:37:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020032',32,'吴拣货','A-02-3,E-01-2,F-02-1',6,6,'2026-11-02 08:39:37','2026-11-02 08:47:37','已完成','2026-11-02 08:37:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(33,'ZT26110200033',10,1,5,70.00,70.00,'104391','2026-11-02 07:30:37',NULL,NULL,'备货中',10,'2026-11-02 07:30:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200330',33,29,3,10.00,30.00,0,1,'2026-11-02 07:30:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200331',33,2,1,3.00,3.00,0,1,'2026-11-02 07:30:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200332',33,9,2,6.50,13.00,0,1,'2026-11-02 07:30:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200333',33,16,3,8.00,24.00,0,1,'2026-11-02 07:30:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020033',33,'张拣货','A-01-2,B-01-1,C-01-1,E-02-2',9,0,'2026-11-02 07:33:37',NULL,'备货中','2026-11-02 07:30:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(34,'ZT26110200034',11,2,12,17.50,17.50,'104528','2026-11-02 09:23:37',NULL,NULL,'备货中',11,'2026-11-02 09:23:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200340',34,32,1,7.50,7.50,0,1,'2026-11-02 09:23:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200341',34,5,2,5.00,10.00,0,1,'2026-11-02 09:23:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020034',34,'吴拣货','A-02-2,F-01-3',3,0,'2026-11-02 09:26:37',NULL,'备货中','2026-11-02 09:23:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(35,'ZT26110200035',12,3,17,21.40,21.40,'104665','2026-11-02 08:16:37',NULL,NULL,'备货中',12,'2026-11-02 08:16:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200350',35,1,2,2.00,4.00,0,1,'2026-11-02 08:16:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200351',35,8,3,1.80,5.40,0,1,'2026-11-02 08:16:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200352',35,15,1,12.00,12.00,0,1,'2026-11-02 08:16:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020035',35,'张拣货','A-01-1,A-01-5,B-03-1',6,0,'2026-11-02 08:19:37',NULL,'备货中','2026-11-02 08:16:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(36,'ZT26110200036',13,4,24,40.10,40.10,'104802','2026-11-02 08:09:37',NULL,NULL,'备货中',13,'2026-11-02 08:09:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200360',36,4,3,3.20,9.60,0,1,'2026-11-02 08:09:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200361',36,11,1,3.00,3.00,0,1,'2026-11-02 08:09:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200362',36,18,2,7.00,14.00,0,1,'2026-11-02 08:09:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200363',36,25,3,4.50,13.50,0,1,'2026-11-02 08:09:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020036',36,'吴拣货','A-02-1,B-01-3,C-01-3,E-01-1',9,0,'2026-11-02 08:12:37',NULL,'备货中','2026-11-02 08:09:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(37,'ZT26110200037',10,1,5,12.00,12.00,'104939','2026-11-02 10:02:37',NULL,NULL,'待备货',10,'2026-11-02 10:02:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200370',37,7,1,3.00,3.00,0,1,'2026-11-02 10:02:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200371',37,14,2,4.50,9.00,0,1,'2026-11-02 10:02:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020037',37,NULL,'A-01-4,B-02-3',3,0,NULL,NULL,'待领取','2026-11-02 10:02:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(38,'ZT26110200038',11,2,12,42.50,42.50,'105076','2026-11-02 08:55:37',NULL,NULL,'待备货',11,'2026-11-02 08:55:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200380',38,10,2,8.50,17.00,0,1,'2026-11-02 08:55:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200381',38,17,3,5.50,16.50,0,1,'2026-11-02 08:55:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200382',38,24,1,9.00,9.00,0,1,'2026-11-02 08:55:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020038',38,NULL,'B-01-2,C-01-2,D-02-2',6,0,NULL,NULL,'待领取','2026-11-02 08:55:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(39,'ZT26110200039',12,3,17,46.60,46.60,'105213','2026-11-02 07:48:37',NULL,NULL,'待备货',12,'2026-11-02 07:48:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200390',39,13,3,5.50,16.50,0,1,'2026-11-02 07:48:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200391',39,20,1,2.50,2.50,0,1,'2026-11-02 07:48:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200392',39,27,2,6.00,12.00,0,1,'2026-11-02 07:48:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200393',39,34,3,5.20,15.60,0,1,'2026-11-02 07:48:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020039',39,NULL,'B-02-2,D-01-1,E-01-3,F-02-2',9,0,NULL,NULL,'待领取','2026-11-02 07:48:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(40,'ZT26110200040',13,4,24,18.00,18.00,'105350','2026-11-02 09:41:37',NULL,NULL,'待备货',13,'2026-11-02 09:41:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200400',40,16,1,8.00,8.00,0,1,'2026-11-02 09:41:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200401',40,23,2,5.00,10.00,0,1,'2026-11-02 09:41:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020040',40,NULL,'C-01-1,D-02-1',3,0,NULL,NULL,'待领取','2026-11-02 09:41:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(41,'ZT26110200041',10,1,5,61.30,61.30,'105487','2026-11-02 08:34:37',NULL,NULL,'待备货',10,'2026-11-02 08:34:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200410',41,19,2,9.50,19.00,0,1,'2026-11-02 08:34:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200411',41,26,3,12.50,37.50,0,1,'2026-11-02 08:34:37');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110200412',41,33,1,4.80,4.80,0,1,'2026-11-02 08:34:37');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611020041',41,NULL,'C-01-4,E-01-2,F-02-1',6,0,NULL,NULL,'待领取','2026-11-02 08:34:37');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(42,'ZT26091500042',11,2,8,74.50,74.50,'105624','2026-09-15 09:47:00',NULL,'课程调整不需要了','已取消',11,'2026-09-15 09:47:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500420',42,22,3,13.00,39.00,0,1,'2026-09-15 09:47:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500421',42,29,1,10.00,10.00,0,1,'2026-09-15 09:47:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500422',42,2,2,3.00,6.00,0,1,'2026-09-15 09:47:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26091500423',42,9,3,6.50,19.50,0,1,'2026-09-15 09:47:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609150042',42,NULL,'A-01-2,B-01-1,D-01-3,E-02-2',9,0,NULL,NULL,'已挂起','2026-09-15 09:47:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(43,'ZT26090100043',12,3,15,19.50,19.50,'105761','2026-09-01 10:54:00',NULL,'重复下单，取消一笔','已取消',12,'2026-09-01 10:54:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26090100430',43,25,1,4.50,4.50,0,1,'2026-09-01 10:54:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26090100431',43,32,2,7.50,15.00,0,1,'2026-09-01 10:54:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2609010043',43,NULL,'E-01-1,F-01-3',3,0,NULL,NULL,'已挂起','2026-09-01 10:54:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(44,'ZT26081800044',13,4,22,29.80,29.80,'105898','2026-08-18 11:01:00',NULL,'错过取货时间','已取消',13,'2026-08-18 11:01:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800440',44,28,2,11.00,22.00,0,1,'2026-08-18 11:01:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800441',44,1,3,2.00,6.00,0,1,'2026-08-18 11:01:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26081800442',44,8,1,1.80,1.80,0,1,'2026-08-18 11:01:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2608180044',44,NULL,'A-01-1,A-01-5,E-02-1',6,0,NULL,NULL,'已挂起','2026-08-18 11:01:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(45,'ZT26073000045',10,1,1,55.70,55.70,'106035','2026-07-30 12:08:00',NULL,'换购其他商品','已取消',10,'2026-07-30 12:08:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000450',45,31,3,8.50,25.50,0,1,'2026-07-30 12:08:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000451',45,4,1,3.20,3.20,0,1,'2026-07-30 12:08:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000452',45,11,2,3.00,6.00,0,1,'2026-07-30 12:08:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26073000453',45,18,3,7.00,21.00,0,1,'2026-07-30 12:08:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2607300045',45,NULL,'A-02-1,B-01-3,C-01-3,F-01-2',9,0,NULL,NULL,'已挂起','2026-07-30 12:08:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(46,'ZT26070500046',11,2,8,11.20,11.20,'106172','2026-07-05 13:15:00',NULL,'临时改选其他时段','已取消',11,'2026-07-05 13:15:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26070500460',46,34,1,5.20,5.20,0,1,'2026-07-05 13:15:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26070500461',46,7,2,3.00,6.00,0,1,'2026-07-05 13:15:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2607050046',46,NULL,'A-01-4,F-02-2',3,0,NULL,NULL,'已挂起','2026-07-05 13:15:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(47,'ZT26060500047',12,3,15,38.00,38.00,'106309','2026-06-05 14:22:00',NULL,'课程调整不需要了','已取消',12,'2026-06-05 14:22:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500470',47,3,2,3.50,7.00,0,1,'2026-06-05 14:22:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500471',47,10,3,8.50,25.50,0,1,'2026-06-05 14:22:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26060500472',47,17,1,5.50,5.50,0,1,'2026-06-05 14:22:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2606050047',47,NULL,'A-01-3,B-01-2,C-01-2',6,0,NULL,NULL,'已挂起','2026-06-05 14:22:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(48,'ZT26051600048',13,4,22,48.00,48.00,'106446','2026-05-16 15:29:00',NULL,'超时未取货，商品按临期流程回滚','超时作废',13,'2026-05-16 15:29:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600480',48,6,3,6.50,19.50,0,1,'2026-05-16 15:29:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600481',48,13,1,5.50,5.50,0,1,'2026-05-16 15:29:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600482',48,20,2,2.50,5.00,0,1,'2026-05-16 15:29:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26051600483',48,27,3,6.00,18.00,0,1,'2026-05-16 15:29:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2605160048',48,'吴拣货','A-02-3,B-02-2,D-01-1,E-01-3',9,9,'2026-05-16 15:31:00','2026-05-16 15:41:00','已完成','2026-05-16 15:29:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(49,'ZT26110100049',10,1,1,22.50,22.50,'106583','2026-11-01 16:36:00',NULL,'自提时段结束 2 小时未取货，系统自动作废','超时作废',10,'2026-11-01 16:36:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100490',49,9,1,6.50,6.50,0,1,'2026-11-01 16:36:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26110100491',49,16,2,8.00,16.00,0,1,'2026-11-01 16:36:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2611010049',49,'张拣货','B-01-1,C-01-1',3,3,'2026-11-01 16:38:00','2026-11-01 16:48:00','已完成','2026-11-01 16:36:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(50,'ZT26103100050',11,2,8,60.80,60.80,'106720','2026-10-31 17:43:00',NULL,'超时未取货，商品按临期流程回滚','超时作废',11,'2026-10-31 17:43:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100500',50,12,2,9.90,19.80,0,1,'2026-10-31 17:43:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100501',50,19,3,9.50,28.50,0,1,'2026-10-31 17:43:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103100502',50,26,1,12.50,12.50,0,1,'2026-10-31 17:43:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610310050',50,'吴拣货','B-02-1,C-01-4,E-01-2',6,6,'2026-10-31 17:45:00','2026-10-31 17:55:00','已完成','2026-10-31 17:43:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(51,'ZT26103000051',12,3,15,78.00,78.00,'106857','2026-10-30 18:50:00',NULL,'自提时段结束 2 小时未取货，系统自动作废','超时作废',12,'2026-10-30 18:50:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000510',51,15,3,12.00,36.00,0,1,'2026-10-30 18:50:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000511',51,22,1,13.00,13.00,0,1,'2026-10-30 18:50:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000512',51,29,2,10.00,20.00,0,1,'2026-10-30 18:50:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26103000513',51,2,3,3.00,9.00,0,1,'2026-10-30 18:50:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610300051',51,'张拣货','A-01-2,B-03-1,D-01-3,E-02-2',9,9,'2026-10-30 18:52:00','2026-10-30 19:02:00','已完成','2026-10-30 18:50:00');
INSERT INTO pickup_order(id,order_no,student_id,point_id,slot_id,goods_amount,pay_amount,pickup_code,order_time,ready_time,cancel_reason,status,create_by,create_time) VALUES(52,'ZT26102800052',13,4,22,16.00,16.00,'106994','2026-10-28 19:57:00',NULL,'超时未取货，商品按临期流程回滚','超时作废',13,'2026-10-28 19:57:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800520',52,18,1,7.00,7.00,0,1,'2026-10-28 19:57:00');
INSERT INTO order_item(item_no,order_id,goods_id,qty,price,amount,out_of_stock,status,create_time) VALUES('MX26102800521',52,25,2,4.50,9.00,0,1,'2026-10-28 19:57:00');
INSERT INTO picking_task(task_no,order_id,picker,shelf_list,plan_qty,real_qty,start_time,finish_time,status,create_time) VALUES('BH2610280052',52,'吴拣货','C-01-3,E-01-1',3,3,'2026-10-28 19:59:00','2026-10-28 20:09:00','已完成','2026-10-28 19:57:00');
-- ---------- 缺货替换（8 条，覆盖待确认/已接受/已拒绝/已退款） ----------
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610270001',27,1,NULL,1,1.00,0,NULL,'待确认',8,'2026-10-27 11:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610240002',29,6,7,1,-3.50,1,'2026-10-24 10:18:37','已接受',8,'2026-10-24 10:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610210003',31,11,12,1,6.90,2,'2026-10-21 09:18:37','已拒绝',8,'2026-10-21 09:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610180004',33,16,NULL,1,-2.50,2,'2026-10-18 08:18:37','已退款',8,'2026-10-18 08:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610150005',34,21,22,1,7.00,0,NULL,'待确认',8,'2026-10-15 07:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610120006',35,26,27,1,-6.50,1,'2026-10-12 06:18:37','已接受',8,'2026-10-12 06:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610090007',36,31,NULL,1,-1.00,2,'2026-10-09 05:18:37','已拒绝',8,'2026-10-09 05:14:37');
INSERT INTO shortage_replace(replace_no,order_id,origin_goods_id,replace_goods_id,qty,diff_amount,confirm_flag,confirm_time,status,create_by,create_time) VALUES('TH2610060008',37,2,3,1,0.50,2,'2026-10-06 04:18:37','已退款',8,'2026-10-06 04:14:37');
-- ---------- 公告 ----------
INSERT INTO sys_notice(id,title,content,publish_time,status,create_time) VALUES(1,'期末周延时营业通知','期末周自提点营业时间延长至 23:00，晚课时段加派备货员。','2026-10-24 11:14:37',1,'2026-10-24 11:14:37');
INSERT INTO sys_notice(id,title,content,publish_time,status,create_time) VALUES(2,'限时促销：饮料第二件半价','本周三至周五，指定饮料第二件半价，促销时段备货量上浮 30%。','2026-10-25 11:14:37',1,'2026-10-25 11:14:37');
INSERT INTO sys_notice(id,title,content,publish_time,status,create_time) VALUES(3,'雨天备货提醒','雨天自提量下降，各点按建议备货量下调 20%，减少短保商品上架。','2026-10-26 11:14:37',1,'2026-10-26 11:14:37');
-- ---------- 预测规则（版本1，权重合计100） ----------
INSERT INTO forecast_rule(id,rule_version,w_history,w_course,w_weather,w_promo,w_turnover,effective_time,status,remark,create_time) VALUES(1,1,30.00,20.00,15.00,20.00,15.00,'2026-09-03 11:14:37',1,'初始规则，按需求第8章权重','2026-09-03 11:14:37');
-- ---------- 预测计算留痕（30 条，含人工修正） ----------
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261102001',1,25,'2026-11-03','08:00:00',6,35.00,'D',52.00,1,'{"base_qty":3,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":40.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-02 11:14:37',NULL,NULL,0,NULL,NULL,'2026-11-02 11:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261101002',1,56,'2026-11-04','18:30:00',11,42.60,'C',55.00,1,'{"base_qty":8,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":43.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-01 10:14:37',NULL,NULL,0,NULL,NULL,'2026-11-01 10:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261031003',1,87,'2026-11-05','17:00:00',16,50.20,'C',58.00,1,'{"base_qty":13,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":46.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-31 09:14:37',NULL,NULL,0,NULL,NULL,'2026-10-31 09:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261030004',1,118,'2026-11-06','12:30:00',21,57.80,'C',61.00,1,'{"base_qty":18,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":49.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-30 08:14:37',27,'当日有社团活动，按经验上调备货量',1,'周运营','2026-10-30 08:26:37','2026-10-30 08:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261029005',1,125,'2026-11-07','11:00:00',26,65.40,'B',64.00,1,'{"base_qty":23,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":52.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-29 07:14:37',NULL,NULL,0,NULL,NULL,'2026-10-29 07:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261028006',1,156,'2026-11-08','09:30:00',31,70.00,'B',67.00,1,'{"base_qty":28,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":55.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-28 06:14:37',NULL,NULL,0,NULL,NULL,'2026-10-28 06:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261027007',1,181,'2026-11-03','08:00:00',6,77.60,'B',70.00,1,'{"base_qty":3,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":58.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-27 05:14:37',NULL,NULL,0,NULL,NULL,'2026-10-27 05:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261026008',1,44,'2026-11-04','18:30:00',11,85.20,'A',73.00,1,'{"base_qty":8,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":61.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-26 04:14:37',NULL,NULL,0,NULL,NULL,'2026-10-26 04:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261025009',1,51,'2026-11-05','17:00:00',16,92.80,'A',76.00,1,'{"base_qty":13,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":64.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-25 03:14:37',NULL,NULL,0,NULL,NULL,'2026-10-25 03:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261102010',1,82,'2026-11-06','12:30:00',21,40.40,'C',79.00,1,'{"base_qty":18,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":67.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-02 02:14:37',NULL,NULL,0,NULL,NULL,'2026-11-02 02:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261101011',1,113,'2026-11-07','11:00:00',26,45.00,'C',82.00,1,'{"base_qty":23,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":70.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-01 01:14:37',32,'当日有社团活动，按经验上调备货量',1,'周运营','2026-11-01 01:26:37','2026-11-01 01:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261031012',1,144,'2026-11-08','09:30:00',31,52.60,'C',85.00,1,'{"base_qty":28,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":73.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-31 00:14:37',NULL,NULL,0,NULL,NULL,'2026-10-31 00:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261030013',1,145,'2026-11-03','08:00:00',6,60.20,'B',88.00,1,'{"base_qty":3,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":76.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-30 11:14:37',NULL,NULL,0,NULL,NULL,'2026-10-30 11:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261029014',1,176,'2026-11-04','18:30:00',11,67.80,'B',91.00,1,'{"base_qty":8,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":79.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-29 10:14:37',NULL,NULL,0,NULL,NULL,'2026-10-29 10:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261028015',1,39,'2026-11-05','17:00:00',16,75.40,'B',94.00,1,'{"base_qty":13,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":82.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-28 09:14:37',NULL,NULL,0,NULL,NULL,'2026-10-28 09:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261027016',1,70,'2026-11-06','12:30:00',21,80.00,'A',52.00,1,'{"base_qty":18,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":85.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-27 08:14:37',NULL,NULL,0,NULL,NULL,'2026-10-27 08:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261026017',1,77,'2026-11-07','11:00:00',26,87.60,'A',55.00,1,'{"base_qty":23,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":88.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-26 07:14:37',NULL,NULL,0,NULL,NULL,'2026-10-26 07:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261025018',1,108,'2026-11-08','09:30:00',31,95.20,'A',58.00,1,'{"base_qty":28,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":41.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-25 06:14:37',37,'当日有社团活动，按经验上调备货量',1,'周运营','2026-10-25 06:26:37','2026-10-25 06:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261102019',1,133,'2026-11-03','08:00:00',6,42.80,'C',61.00,1,'{"base_qty":3,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":44.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-02 05:14:37',NULL,NULL,0,NULL,NULL,'2026-11-02 05:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261101020',1,164,'2026-11-04','18:30:00',11,50.40,'C',64.00,1,'{"base_qty":8,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":47.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-01 04:14:37',NULL,NULL,0,NULL,NULL,'2026-11-01 04:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261031021',1,171,'2026-11-05','17:00:00',16,55.00,'C',67.00,1,'{"base_qty":13,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":50.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-31 03:14:37',NULL,NULL,0,NULL,NULL,'2026-10-31 03:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261030022',1,34,'2026-11-06','12:30:00',21,62.60,'B',70.00,1,'{"base_qty":18,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":53.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-30 02:14:37',NULL,NULL,0,NULL,NULL,'2026-10-30 02:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261029023',1,65,'2026-11-07','11:00:00',26,70.20,'B',73.00,1,'{"base_qty":23,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":56.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-29 01:14:37',NULL,NULL,0,NULL,NULL,'2026-10-29 01:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261028024',1,96,'2026-11-08','09:30:00',31,77.80,'B',76.00,1,'{"base_qty":28,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":59.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-28 00:14:37',NULL,NULL,0,NULL,NULL,'2026-10-28 00:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261027025',1,97,'2026-11-03','08:00:00',6,85.40,'A',79.00,1,'{"base_qty":3,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":62.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-27 11:14:37',12,'当日有社团活动，按经验上调备货量',1,'周运营','2026-10-27 11:26:37','2026-10-27 11:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261026026',1,128,'2026-11-04','18:30:00',11,90.00,'A',82.00,1,'{"base_qty":8,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":65.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-26 10:14:37',NULL,NULL,0,NULL,NULL,'2026-10-26 10:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261025027',1,159,'2026-11-05','17:00:00',16,37.60,'D',85.00,1,'{"base_qty":13,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":68.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-25 09:14:37',NULL,NULL,0,NULL,NULL,'2026-10-25 09:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261102028',1,190,'2026-11-06','12:30:00',21,45.20,'C',88.00,1,'{"base_qty":18,"course_tag":"早八","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":71.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-02 08:14:37',NULL,NULL,0,NULL,NULL,'2026-11-02 08:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261101029',1,29,'2026-11-07','11:00:00',26,52.80,'C',91.00,1,'{"base_qty":23,"course_tag":"晚课","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":74.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-11-01 07:14:37',NULL,NULL,0,NULL,NULL,'2026-11-01 07:14:37');
INSERT INTO forecast_calc(calc_no,point_id,slot_id,slot_date,start_time,suggest_qty,score,level,confidence,rule_version,snapshot_json,calc_time,manual_qty,manual_reason,manual_flag,manual_by,manual_time,create_time) VALUES('FC20261031030',1,60,'2026-11-08','09:30:00',31,60.40,'B',94.00,1,'{"base_qty":28,"course_tag":"常规","course_coef":1.35,"weather":"晴天","weather_coef":1.0,"promo_coef":1.0,"turnover_adj":0.12,"scores":{"history":77.0,"course":70.0,"weather":50.0,"promo":50.0,"turnover":78.0}}','2026-10-31 06:14:37',NULL,NULL,0,NULL,NULL,'2026-10-31 06:14:37');
-- ---------- 操作日志 ----------
INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip,create_time) VALUES('自提订单','创建','ZT26090100001','学生下单 3 件商品',1,'系统管理员','2026-11-01 10:14:37','127.0.0.1','2026-11-01 10:14:37');
INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip,create_time) VALUES('备货任务','领取','BH2609010001','备货员张拣货领取任务',1,'系统管理员','2026-10-31 09:14:37','127.0.0.1','2026-10-31 09:14:37');
INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip,create_time) VALUES('核销台','核销','ZT26090100001','核销方式：扫码',1,'系统管理员','2026-10-30 08:14:37','127.0.0.1','2026-10-30 08:14:37');
INSERT INTO sys_oper_log(module,oper_type,biz_no,content,oper_id,oper_name,oper_time,ip,create_time) VALUES('预测看板','规则修改','RULE-v2','历史销量权重 30→35',1,'系统管理员','2026-10-29 07:14:37','127.0.0.1','2026-10-29 07:14:37');

-- ---------- 统计校验 ----------
SELECT '商品' AS 表名, COUNT(*) AS 条数 FROM shop_goods UNION ALL SELECT '订单', COUNT(*) FROM pickup_order UNION ALL SELECT '明细', COUNT(*) FROM order_item UNION ALL SELECT '时段', COUNT(*) FROM pick_slot UNION ALL SELECT '用户', COUNT(*) FROM sys_user;-- NEW-070 站内消息种子数据（补充：状态流转需写入站内消息，初始库不应为空）
INSERT IGNORE INTO `sys_message` (`id`,`receiver_id`,`title`,`content`,`biz_type`,`biz_id`,`read_flag`,`create_by`,`create_time`) VALUES
(9001, 1,'超时作废订单待复核','订单 PK20261028003 自提时段结束后 2 小时未取货，已自动作废并按临期流程回滚库存。','ORDER',3,0,1,'2026-10-28 21:40:12'),
(9002, 4,'备货任务超时提醒','备货任务 PK20261030007 已超过 15 分钟未完成，请安排其他备货员接手。','PICKING',7,0,8,'2026-10-30 12:18:35'),
(9003, 8,'新的备货任务已生成','订单 PK20261101012 已支付，拣货清单按货架位排序完成，共 6 项商品。','PICKING',12,1,1,'2026-11-01 09:12:04'),
(9004,10,'缺货替换待确认','你订单中的「农夫山泉 550ml」缺货，已推荐同规格替代商品，请在 10 分钟内确认。','REPLACE',5,0,8,'2026-11-01 17:36:22'),
(9005, 6,'取货码核销失败锁定','连续 3 次输入错误取货码，订单 PK20261026009 核销已锁定 10 分钟。','VERIFY',9,1,6,'2026-10-26 18:02:47'),
(9006, 2,'本周预测复盘已生成','11 月第 1 周备货量预测偏差超过 30% 的时段共 4 个，复盘记录已汇总，请调整权重系数。','FORECAST',30,0,2,'2026-11-02 08:30:00');
