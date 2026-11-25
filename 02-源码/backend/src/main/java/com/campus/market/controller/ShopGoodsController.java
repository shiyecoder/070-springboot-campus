package com.campus.market.controller;

import com.campus.market.entity.ShopGoods;
import com.campus.market.service.ShopGoodsService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 校园超市商品标准 CRUD 接口，统一前缀 /api/shop-goods */
@RestController
@RequestMapping("/api/shop-goods")
public class ShopGoodsController extends BaseCrudController<ShopGoods> {

    private final ShopGoodsService service;

    public ShopGoodsController(ShopGoodsService service) {
        this.service = service;
    }

    @Override
    protected ShopGoodsService svc() {
        return service;
    }

    @Override
    protected String[] keywordColumns() {
        return new String[]{"goods_no", "name"};
    }

    @Override
    protected String statusColumn() {
        return "status";
    }
}
