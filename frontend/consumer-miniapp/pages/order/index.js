import { fetchTwentyMallBindingsFromDatabase } from "../../utils/auth"
import { enrichOrderDisplay } from "../../utils/order-display"

const FILTERS = [
  { key: "ALL", label: "全部" },
  { key: "NONE", label: "未申请" },
  { key: "AFTER_SALE", label: "售后中" },
  { key: "DONE", label: "售后结束" }
]

function cleanProductTitle(title) {
  return String(title || "").replace(/^万象商城\s*/, "").trim()
}

function afterSaleTone(afterSale) {
  if (afterSale === "未申请") return "plain"
  if (afterSale === "已完成" || afterSale === "已结束") return "success"
  return "warning"
}

function groupOrdersByMerchant(orders) {
  const shopMap = {}
  orders.forEach((order) => {
    const merchant = order.merchant || "未知商家"
    if (!shopMap[merchant]) {
      shopMap[merchant] = {
        merchant,
        orders: []
      }
    }
    shopMap[merchant].orders.push(order)
  })
  return Object.keys(shopMap).map((merchant) => shopMap[merchant])
}

function orderMatchesFilter(order, filter) {
  if (filter === "ALL") return true
  if (filter === "AFTER_SALE") return order.afterSale && order.afterSale !== "未申请" && order.afterSale !== "已完成"
  if (filter === "NONE") return order.afterSale === "未申请"
  if (filter === "DONE") return order.afterSale === "已完成" || order.afterSale === "已结束"
  return true
}

function buildFilteredGroups(groups, filter) {
  return groups.map((group) => {
    const filteredOrders = group.orders.filter((order) => orderMatchesFilter(order, filter))
    return {
      ...group,
      orders: filteredOrders,
      shops: groupOrdersByMerchant(filteredOrders)
    }
  })
}

Page({
  data: {
    orders: [],
    orderGroups: [],
    filteredOrderGroups: [],
    platformBound: false,
    filters: FILTERS,
    activeFilter: "ALL"
  },
  onShow() {
    if (typeof this.getTabBar === "function" && this.getTabBar()) {
      this.getTabBar().setData({ selected: 1 })
    }
    fetchTwentyMallBindingsFromDatabase({
      success: (bindings) => this.loadOrdersByBindings(bindings),
      fail: (bindings) => this.loadOrdersByBindings(bindings)
    })
  },
  loadOrdersByBindings(bindings) {
    if (!bindings.length) {
      this.setData({ orders: [], orderGroups: [], filteredOrderGroups: [], platformBound: false })
      return
    }
    const requests = bindings.map((binding) => new Promise((resolve) => {
      wx.request({
        url: `http://localhost:8080/api/twenty-mall/consumer/orders?accountNo=${binding.accountNo}`,
        success: (res) => {
          const list = (res.data && res.data.data) || []
          const groupOrders = list.map((item) => enrichOrderDisplay({
            no: item.no,
            title: cleanProductTitle(item.title),
            status: item.status,
            afterSale: item.afterSale,
            platform: "万象商城",
            accountNo: binding.accountNo,
            merchant: item.merchant,
            price: item.price,
            image: item.image,
            spec: item.spec,
            reviewed: !!item.reviewed,
            service: item.afterSale === "未申请" ? "可申请售后" : "售后处理中",
            afterSaleTone: afterSaleTone(item.afterSale)
          }))
          resolve({
            platform: "万象商城",
            accountNo: binding.accountNo,
            orders: groupOrders,
            shops: groupOrdersByMerchant(groupOrders)
          })
        },
        fail: () => {
          resolve({
            platform: "万象商城",
            accountNo: binding.accountNo,
            orders: [],
            shops: []
          })
        }
      })
    }))
    Promise.all(requests).then((groups) => {
      const allOrders = groups.reduce((all, group) => all.concat(group.orders), [])
      this.setData({
        orderGroups: groups,
        filteredOrderGroups: buildFilteredGroups(groups, this.data.activeFilter),
        orders: allOrders,
        platformBound: true
      })
    })
  },
  switchFilter(e) {
    const key = e.currentTarget.dataset.key || "ALL"
    this.setData({
      activeFilter: key,
      filteredOrderGroups: buildFilteredGroups(this.data.orderGroups, key)
    })
  },
  goDetail(e) {
    if (!this.data.platformBound) return
    const no = e.currentTarget.dataset.no
    if (!no) {
      wx.showToast({ title: "订单编号缺失", icon: "none" })
      return
    }
    wx.navigateTo({
      url: `/pages/product/index?no=${no}`,
      fail: () => {
        wx.showToast({ title: "订单详情打开失败", icon: "none" })
      }
    })
  },
  goBind() {
    wx.switchTab({ url: "/pages/home/index" })
  }
})
