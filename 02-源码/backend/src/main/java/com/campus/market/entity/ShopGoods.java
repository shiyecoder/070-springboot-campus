package com.campus.market.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 校园超市商品实体，对应数据库表 shop_goods。
 * 逻辑删除字段 deleted 由 MyBatis-Plus 全局拦截，查询自动过滤 deleted=1。
 */
@Data
@TableName("shop_goods")
public class ShopGoods {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String goodsNo;
    private String name;
    private String categoryCode;
    private String spec;
    private BigDecimal salePrice;
    private Integer stockQty;
    private Integer limitQty;
    private String shelfCode;
    private Integer isCold;
    private Integer status;
    private String image;
    private LocalDateTime createTime;
    @TableLogic
    private Integer deleted;
}
