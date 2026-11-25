package com.campus.market.service;

import com.campus.market.entity.ShopGoods;
import com.campus.market.mapper.ShopGoodsMapper;
import org.springframework.stereotype.Service;

@Service
public class ShopGoodsService extends BaseService<ShopGoods> {
    public ShopGoodsService(ShopGoodsMapper mapper) {
        this.baseMapper = mapper;
    }
}
