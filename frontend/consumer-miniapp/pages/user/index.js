import { clearDemoToken, clearPrimaryAccountData, fetchLocalPlatformBindingsFromDatabase, fetchPrimaryProfileFromDatabase, getConsumerAddresses, getConsumerProfile, getLocalPlatformBindings, getLocalPlatformConfig, getPrimaryPhone } from "../../utils/auth"

const LOCAL_PLATFORM_CODES = ["TWENTY_MALL", "YUEGOU_MARKET"]

const defaultProfile = {
  nickname: "",
  phone: "",
  avatar: "",
  address: "",
  bindPlatform: "未绑定电商平台",
  lastConsult: "暂无"
}

Page({
  data: {
    profile: defaultProfile,
    cancelDialogVisible: false,
    cancelCountdown: 5,
    cancelConfirmEnabled: false
  },
  onUnload() {
    this.clearCancelTimer()
  },
  onShow() {
    if (typeof this.getTabBar === "function" && this.getTabBar()) {
      this.getTabBar().setData({ selected: 3 })
    }
    this.refreshProfile()
  },
  refreshProfile() {
    const phone = getPrimaryPhone()
    const localProfile = getConsumerProfile()
    const addresses = getConsumerAddresses()
    const bindings = this.localPlatformBindings()
    const nextProfile = localProfile ? { ...defaultProfile, ...localProfile } : { ...defaultProfile }
    nextProfile.phone = this.displayPhone(nextProfile.phone) || this.displayPhone(phone)
    nextProfile.bindPlatform = this.bindingText(bindings)
    nextProfile.lastConsult = wx.getStorageSync(`consumerLastConsultAt:${phone}`) || "暂无"
    const defaultAddress = addresses.find((item) => item.isDefault) || addresses[0]
    if (defaultAddress && defaultAddress.fullAddress) {
      nextProfile.address = defaultAddress.fullAddress
    }
    this.setData({ profile: nextProfile })
    fetchPrimaryProfileFromDatabase({
      success: (profile) => this.applyProfileFromDatabase(profile),
      fail: () => {}
    })
    this.fetchAllLocalPlatformBindings({
      success: (dbBindings) => this.applyBindingCount(dbBindings),
      fail: (cachedBindings) => this.applyBindingCount(cachedBindings)
    })
  },
  applyProfileFromDatabase(profile) {
    const phone = getPrimaryPhone()
    this.setData({
      profile: {
        ...this.data.profile,
        nickname: profile.nickname || "",
        phone: this.displayPhone(profile.phone) || this.displayPhone(phone),
        avatar: profile.avatar || "",
        bindPlatform: profile.bindingCount ? `已绑定 ${profile.bindingCount} 个电商账号` : this.data.profile.bindPlatform
      }
    })
  },
  applyBindingCount(bindings) {
    this.setData({
      "profile.bindPlatform": this.bindingText(bindings)
    })
  },
  localPlatformBindings() {
    return LOCAL_PLATFORM_CODES.reduce((all, platformCode) => {
      const config = getLocalPlatformConfig(platformCode)
      const rows = getLocalPlatformBindings(platformCode).map((item) => ({
        ...item,
        platformCode,
        platformName: item.platform || config.name
      }))
      return all.concat(rows)
    }, [])
  },
  fetchAllLocalPlatformBindings({ success, fail } = {}) {
    const tasks = LOCAL_PLATFORM_CODES.map((platformCode) => new Promise((resolve) => {
      const config = getLocalPlatformConfig(platformCode)
      fetchLocalPlatformBindingsFromDatabase(platformCode, {
        success: (bindings) => resolve((bindings || []).map((item) => ({
          ...item,
          platformCode,
          platformName: item.platform || config.name
        }))),
        fail: (bindings) => resolve((bindings || []).map((item) => ({
          ...item,
          platformCode,
          platformName: item.platform || config.name
        })))
      })
    }))
    Promise.all(tasks).then((groups) => {
      const bindings = groups.reduce((all, group) => all.concat(group), [])
      if (success) success(bindings)
    }).catch(() => {
      if (fail) fail(this.localPlatformBindings())
    })
  },
  bindingText(bindings = []) {
    if (!bindings.length) {
      return "未绑定电商平台"
    }
    const platformNames = Array.from(new Set(bindings.map((item) => item.platformName || item.platform).filter(Boolean)))
    if (platformNames.length === 1) {
      return platformNames[0]
    }
    return platformNames.length ? platformNames.join("、") : `${bindings.length} 个电商账号`
  },
  editProfile() {
    wx.navigateTo({ url: "/pages/profile-edit/index" })
  },
  manageAddress() {
    wx.navigateTo({ url: "/pages/address/index" })
  },
  logout() {
    wx.showModal({
      title: "退出登录",
      content: "确定要退出当前账号吗？",
      confirmText: "退出",
      success: (res) => {
        if (!res.confirm) return
        clearDemoToken()
        wx.reLaunch({ url: "/pages/login/index" })
      }
    })
  },
  openCancelAccountDialog() {
    this.clearCancelTimer()
    this.setData({
      cancelDialogVisible: true,
      cancelCountdown: 5,
      cancelConfirmEnabled: false
    })
    this.cancelTimer = setInterval(() => {
      const next = this.data.cancelCountdown - 1
      if (next <= 0) {
        this.clearCancelTimer()
        this.setData({
          cancelCountdown: 0,
          cancelConfirmEnabled: true
        })
        return
      }
      this.setData({ cancelCountdown: next })
    }, 1000)
  },
  closeCancelAccountDialog() {
    this.clearCancelTimer()
    this.setData({
      cancelDialogVisible: false,
      cancelCountdown: 5,
      cancelConfirmEnabled: false
    })
  },
  confirmCancelAccount() {
    if (!this.data.cancelConfirmEnabled) return
    clearPrimaryAccountData()
    wx.reLaunch({ url: "/pages/login/index" })
  },
  clearCancelTimer() {
    if (this.cancelTimer) {
      clearInterval(this.cancelTimer)
      this.cancelTimer = null
    }
  },
  displayPhone(phone) {
    if (!phone || phone === "guest" || phone.startsWith("wx_")) {
      return ""
    }
    return phone
  }
})
