import { clearDemoToken, clearPrimaryAccountData, fetchPrimaryProfileFromDatabase, fetchTwentyMallBindingsFromDatabase, getConsumerAddresses, getConsumerProfile, getPrimaryPhone, getTwentyMallBindings } from "../../utils/auth"

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
    const bindings = getTwentyMallBindings()
    const nextProfile = localProfile ? { ...defaultProfile, ...localProfile } : { ...defaultProfile }
    nextProfile.phone = this.displayPhone(nextProfile.phone) || this.displayPhone(phone)
    nextProfile.bindPlatform = bindings.length ? `已绑定 ${bindings.length} 个电商账号` : "未绑定电商平台"
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
    fetchTwentyMallBindingsFromDatabase({
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
      "profile.bindPlatform": bindings.length ? `已绑定 ${bindings.length} 个电商账号` : "未绑定电商平台"
    })
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
