import { saveConsumerProfile, saveDemoToken, savePrimaryAccount } from "../../utils/auth"

Page({
  data: {
    phone: "",
    password: ""
  },
  onPhoneInput(e) {
    this.setData({ phone: e.detail.value })
  },
  onPasswordInput(e) {
    this.setData({ password: e.detail.value })
  },
  onLogin() {
    const phone = this.data.phone.trim()
    const password = this.data.password.trim()
    if (!/^1\d{10}$/.test(phone)) {
      wx.showToast({ title: "请输入正确的11位手机号", icon: "none" })
      return
    }
    if (!password) {
      wx.showToast({ title: "请输入密码", icon: "none" })
      return
    }
    wx.showLoading({ title: "登录中" })
    wx.request({
      url: "http://localhost:8080/api/twenty-mall/consumer/password-login",
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: { phone, password },
      success: (res) => {
        wx.hideLoading()
        const payload = res.data || {}
        if (payload.code !== "200" || !payload.data) {
          wx.showToast({ title: payload.message || "手机号或密码错误", icon: "none" })
          return
        }
        const account = payload.data
        saveDemoToken()
        savePrimaryAccount(account.accountNo || phone)
        saveConsumerProfile({
          nickname: account.displayName || account.accountNo || phone,
          phone: this.displayPhone(account.phone) || phone,
          avatar: account.avatar || "",
          bindingCount: 0
        })
        wx.switchTab({ url: "/pages/home/index" })
      },
      fail: () => {
        wx.hideLoading()
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      }
    })
  },
  displayPhone(phone) {
    if (!phone || phone === "guest" || phone.startsWith("wx_")) {
      return ""
    }
    return phone
  }
})
