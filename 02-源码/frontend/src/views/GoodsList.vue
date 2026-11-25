<template>
  <CrudPage :config="config" />
</template>

<script setup>
import CrudPage from '../components/CrudPage.vue'

// 商品管理：库存低于 5 件自动转售罄的门店规则在后端校验，前端只做录入与状态展示
const config = {
  title: '商品管理',
  sub: '维护在售商品的价格、库存、限购与货架位；冷藏商品备货时优先拣选，下架前需先处理待备货订单',
  api: '/api/shop-goods',
  addText: '新增商品',
  deleteText: '删除',
  actionWidth: 150,
  titleProp: 'name',
  searchPlaceholder: '商品编号 / 名称',
  statusOptions: [
    { label: '在售', value: '1' }, { label: '已下架', value: '0' }, { label: '已售罄', value: '2' }
  ],
  columns: [
    { prop: 'name', label: '商品', type: 'goods', width: 240 },
    { prop: 'goods_no', label: '商品编号', width: 130 },
    { prop: 'category_code', label: '分类', width: 80 },
    { prop: 'sale_price', label: '售价', type: 'money', width: 90 },
    { prop: 'stock_qty', label: '库存', width: 70 },
    { prop: 'limit_qty', label: '限购', width: 64 },
    { prop: 'is_cold', label: '温层', type: 'bool', width: 80 },
    { prop: 'status', label: '状态', type: 'status', width: 90, map: { 1: '在售', 0: '已下架', 2: '已售罄' } },
    { prop: 'create_time', label: '创建时间', type: 'datetime', width: 160 }
  ],
  formFields: [
    { prop: 'name', label: '商品名称', required: true },
    { prop: 'category_code', label: '分类', type: 'select', options: ['饮料', '零食', '文具', '日用品', '生鲜', '面包'], required: true },
    { prop: 'spec', label: '规格', required: true, placeholder: '如 500ml、80g' },
    { prop: 'sale_price', label: '售价', type: 'number', precision: 2, step: 0.5, required: true },
    { prop: 'stock_qty', label: '库存数量', type: 'number', precision: 0, required: true },
    { prop: 'limit_qty', label: '限购数量', type: 'number', precision: 0, default: 0 },
    { prop: 'shelf_code', label: '货架位', required: true, placeholder: '格式 区-排-位，如 B-03-2' },
    { prop: 'is_cold', label: '是否冷藏', type: 'switch' },
    { prop: 'status', label: '状态', type: 'select', options: [{ label: '在售', value: 1 }, { label: '已下架', value: 0 }, { label: '已售罄', value: 2 }] },
    { prop: 'image', label: '商品图', placeholder: '上传后自动回填相对路径' }
  ]
}
</script>
