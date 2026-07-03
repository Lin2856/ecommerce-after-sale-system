import { canBindLocalPlatformAccount, fetchLocalPlatformBindingsFromDatabase, getConsumerAddresses, getLocalPlatformConfig, getPrimaryPhone, occupyLocalPlatformBinding, removeLocalPlatformBinding, saveConsumerAddresses, saveLocalPlatformBinding } from "../../utils/auth"

function buildPlatforms() {
  return [
    { name: "抖音商城绑定", icon: "/assets/platforms/douyin.png", status: "待绑定" },
    { name: "淘宝绑定", icon: "/assets/platforms/taobao.png", status: "待绑定" },
    { name: "拼多多绑定", icon: "/assets/platforms/pinduoduo.png", status: "待绑定" },
    { name: "京东绑定", icon: "/assets/platforms/jd.png", status: "待绑定" },
    { code: "TWENTY_MALL", name: "万象商城", icon: "/assets/platforms/twenty-mall.png", status: "本地模拟平台", wide: true },
    { code: "YUEGOU_MARKET", name: "悦购集市", icon: "/assets/platforms/yuegou-market.svg", status: "本地模拟平台", wide: true }
  ]
}

function buildOpenPlatforms() {
  return buildPlatforms().filter((item) => !item.wide)
}

function splitAddress(fullAddress) {
  const address = fullAddress || ""
  const match = address.match(/^(.+[省市区县])(.+)$/)
  if (!match) {
    return {
      region: "",
      detail: address
    }
  }
  return {
    region: match[1],
    detail: match[2]
  }
}

Page({
  data: {
    platforms: buildPlatforms(),
    openPlatforms: buildOpenPlatforms(),
    localPlatforms: buildPlatforms().filter((item) => item.wide).map((item) => ({ ...item, bindings: [], boundCount: 0 })),
    localPlatformBindings: {},
    selfBuiltDialogVisible: false,
    selectedPlatformCode: "TWENTY_MALL",
    selectedPlatformName: "万象商城",
    selfBuiltAccount: "",
    selfBuiltPassword: ""
  },
  onShow() {
    if (typeof this.getTabBar === "function" && this.getTabBar()) {
      this.getTabBar().setData({ selected: 0 })
    }
    this.refreshLocalPlatformBindings()
  },
  refreshLocalPlatformBindings() {
    const platformCodes = ["TWENTY_MALL", "YUEGOU_MARKET"]
    platformCodes.forEach((platformCode) => {
      fetchLocalPlatformBindingsFromDatabase(platformCode, {
        success: (bindings) => this.applyLocalPlatformBindings(platformCode, bindings),
        fail: (bindings) => this.applyLocalPlatformBindings(platformCode, bindings)
      })
    })
  },
  applyLocalPlatformBindings(platformCode, bindings) {
    bindings.forEach((binding) => occupyLocalPlatformBinding(platformCode, binding.accountNo))
    const nextBindings = {
      ...this.data.localPlatformBindings,
      [platformCode]: bindings
    }
    const localPlatforms = buildPlatforms()
      .filter((item) => item.wide)
      .map((item) => ({
        ...item,
        bindings: nextBindings[item.code] || [],
        boundCount: (nextBindings[item.code] || []).length
      }))
    this.setData({
      platforms: buildPlatforms(),
      openPlatforms: buildOpenPlatforms(),
      localPlatforms,
      localPlatformBindings: nextBindings
    })
  },
  bindPlatform(e) {
    const name = e.currentTarget.dataset.name
    const platformCode = e.currentTarget.dataset.code
    if (platformCode === "TWENTY_MALL" || platformCode === "YUEGOU_MARKET") {
      const config = getLocalPlatformConfig(platformCode)
      this.setData({
        selectedPlatformCode: platformCode,
        selectedPlatformName: config.name,
        selfBuiltDialogVisible: true,
        selfBuiltAccount: "",
        selfBuiltPassword: ""
      })
      return
    }
    wx.showToast({ title: `${name}功能接入中`, icon: "none" })
  },
  onSelfBuiltAccountInput(e) {
    this.setData({ selfBuiltAccount: e.detail.value })
  },
  onSelfBuiltPasswordInput(e) {
    this.setData({ selfBuiltPassword: e.detail.value })
  },
  closeSelfBuiltDialog() {
    this.setData({ selfBuiltDialogVisible: false })
  },
  submitSelfBuiltBind() {
    const platformCode = this.data.selectedPlatformCode
    const config = getLocalPlatformConfig(platformCode)
    const accountNo = this.data.selfBuiltAccount.trim()
    const password = this.data.selfBuiltPassword.trim()
    if (!accountNo || !password) {
      wx.showToast({ title: `请输入${config.name}账号和密码`, icon: "none" })
      return
    }
    if (!canBindLocalPlatformAccount(platformCode, accountNo)) {
      wx.showToast({ title: "该账号已被绑定", icon: "none" })
      return
    }
    wx.request({
      url: `http://localhost:8080${config.apiPrefix}/bind`,
      method: "POST",
      data: {
        accountNo,
        password,
        role: "CONSUMER",
        primaryAccountNo: getPrimaryPhone(),
        primaryAccountType: "CONSUMER",
        primaryDisplayName: ""
      },
      success: (res) => {
        if (res.data && res.data.code === "200") {
          saveLocalPlatformBinding(platformCode, {
            accountNo,
            role: "CONSUMER",
            platform: config.name
          })
          this.refreshLocalPlatformBindings()
          this.setData({ selfBuiltDialogVisible: false, selfBuiltAccount: "", selfBuiltPassword: "" })
          this.importLocalPlatformAddress(platformCode, accountNo)
          wx.showToast({ title: `${config.name}绑定成功`, icon: "success" })
          return
        }
        wx.showToast({ title: res.data.message || "账号或密码错误", icon: "none" })
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      }
    })
  },
  importLocalPlatformAddress(platformCode, accountNo) {
    const config = getLocalPlatformConfig(platformCode)
    wx.request({
      url: `http://localhost:8080${config.apiPrefix}/profile?accountNo=${accountNo}&role=CONSUMER`,
      success: (res) => {
        const data = res.data && res.data.data
        if (!data || !data.address) return
        const addresses = getConsumerAddresses()
        const sourceId = `${platformCode.toLowerCase()}_${accountNo}`
        const parts = splitAddress(data.address)
        const importedAddress = {
          id: sourceId,
          name: data.displayName || `${config.name}用户`,
          phone: data.phone || "13338907583",
          region: parts.region,
          detail: parts.detail,
          fullAddress: data.address,
          source: config.name,
          sourceAccountNo: accountNo,
          isDefault: addresses.length === 0
        }
        const exists = addresses.some((item) => item.id === sourceId)
        let nextAddresses = exists
          ? addresses.map((item) => item.id === sourceId ? { ...item, ...importedAddress, isDefault: item.isDefault } : item)
          : [...addresses, importedAddress]
        if (!nextAddresses.some((item) => item.isDefault)) {
          nextAddresses = nextAddresses.map((item, index) => ({
            ...item,
            isDefault: index === 0
          }))
        }
        saveConsumerAddresses(nextAddresses)
      }
    })
  },
  unbindLocalPlatform(e) {
    const accountNo = e.currentTarget.dataset.account
    const platformCode = e.currentTarget.dataset.code || "TWENTY_MALL"
    const config = getLocalPlatformConfig(platformCode)
    wx.showModal({
      title: "解除绑定",
      content: `确定要解绑${config.name}账号 ${accountNo} 吗？解绑后该账号订单和客服会话将不再显示。`,
      confirmText: "解绑",
      confirmColor: "#d92d20",
      success: (res) => {
        if (!res.confirm) return
        wx.request({
          url: `http://localhost:8080${config.apiPrefix}/unbind`,
          method: "POST",
          header: { "Content-Type": "application/json" },
          data: {
            accountNo,
            role: "CONSUMER",
            primaryAccountNo: getPrimaryPhone(),
            primaryAccountType: "CONSUMER"
          },
          complete: () => {
            removeLocalPlatformBinding(platformCode, accountNo)
            this.refreshLocalPlatformBindings()
            wx.showToast({ title: "已解绑", icon: "success" })
          }
        })
      }
    })
  }
})
