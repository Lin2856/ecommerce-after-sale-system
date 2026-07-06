import { saveConsumerProfile, saveDemoToken, savePrimaryAccount } from "../../utils/auth"

Page({
  data: {
    phone: "",
    code: "",
    sendingCode: false,
    smsCooldown: 0,
    importWechatAvatar: true,
    showWechatAvatarPicker: false,
    pendingWechatPhoneCode: "",
    wechatAvatar: ""
  },
  onPhoneInput(e) {
    this.setData({ phone: e.detail.value })
  },
  onCodeInput(e) {
    this.setData({ code: e.detail.value })
  },
  onUnload() {
    this.clearSmsTimer()
  },
  sendVerificationCode() {
    if (this.data.sendingCode || this.data.smsCooldown > 0) return
    const phone = this.data.phone.trim()
    if (!/^1\d{10}$/.test(phone)) {
      wx.showToast({ title: "请输入正确的11位手机号", icon: "none" })
      return
    }
    this.setData({ sendingCode: true })
    wx.request({
      url: "http://localhost:8080/api/twenty-mall/consumer/verification-code/send",
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: { phone },
      success: (res) => {
        const payload = res.data || {}
        if (payload.code !== "200" || !payload.data) {
          wx.showToast({ title: payload.message || "验证码发送失败", icon: "none" })
          return
        }
        const devCode = payload.data.devCode || ""
        wx.showToast({
          title: devCode ? `验证码：${devCode}` : "验证码已发送",
          icon: "none",
          duration: 3000
        })
        this.startSmsCooldown()
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      },
      complete: () => {
        this.setData({ sendingCode: false })
      }
    })
  },
  startSmsCooldown() {
    this.clearSmsTimer()
    this.setData({ smsCooldown: 60 })
    this.smsTimer = setInterval(() => {
      const next = this.data.smsCooldown - 1
      if (next <= 0) {
        this.clearSmsTimer()
        this.setData({ smsCooldown: 0 })
        return
      }
      this.setData({ smsCooldown: next })
    }, 1000)
  },
  clearSmsTimer() {
    if (this.smsTimer) {
      clearInterval(this.smsTimer)
      this.smsTimer = null
    }
  },
  toggleWechatAvatar() {
    this.setData({ importWechatAvatar: !this.data.importWechatAvatar })
  },
  onChooseWechatAvatar(e) {
    const avatarUrl = e.detail && e.detail.avatarUrl
    if (!avatarUrl) {
      wx.showToast({ title: "暂未选择头像", icon: "none" })
      return
    }
    this.setData({ wechatAvatar: avatarUrl })
    wx.showToast({ title: "头像已选择", icon: "success" })
  },
  onLogin() {
    const phone = this.data.phone.trim()
    const code = this.data.code.trim()
    if (!/^1\d{10}$/.test(phone)) {
      wx.showToast({ title: "请输入正确的11位手机号", icon: "none" })
      return
    }
    if (!/^\d{6}$/.test(code)) {
      wx.showToast({ title: "请输入6位验证码", icon: "none" })
      return
    }
    wx.showLoading({ title: "登录中" })
    wx.request({
      url: "http://localhost:8080/api/twenty-mall/consumer/phone-login",
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: { phone, code },
      success: (res) => {
        wx.hideLoading()
        const payload = res.data || {}
        if (payload.code !== "200" || !payload.data) {
          wx.showToast({ title: payload.message || "手机号或验证码错误", icon: "none" })
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
  onWechatLogin(e) {
    const phoneCode = e.detail && e.detail.code
    if (!phoneCode) {
      wx.showToast({ title: "需要授权手机号后才能微信登录", icon: "none" })
      return
    }
    if (this.data.importWechatAvatar && !this.data.wechatAvatar) {
      this.setData({
        showWechatAvatarPicker: true,
        pendingWechatPhoneCode: phoneCode
      })
      wx.showToast({ title: "请选择微信头像", icon: "none" })
      return
    }
    this.continueWechatLogin(phoneCode)
  },
  continueWechatLogin(phoneCode) {
    wx.showLoading({ title: "微信登录中" })
    wx.login({
      success: (loginRes) => {
        if (!loginRes.code) {
          wx.hideLoading()
          wx.showToast({ title: "微信登录失败，请重试", icon: "none" })
          return
        }
        this.prepareWechatProfile({
          success: (profile) => this.submitWechatLogin(loginRes.code, phoneCode, profile)
        })
      },
      fail: () => {
        wx.hideLoading()
        wx.showToast({ title: "微信登录失败，请检查小程序环境", icon: "none" })
      }
    })
  },
  skipWechatAvatar() {
    const phoneCode = this.data.pendingWechatPhoneCode
    if (!phoneCode) return
    this.setData({
      importWechatAvatar: false,
      showWechatAvatarPicker: false,
      wechatAvatar: ""
    })
    this.continueWechatLogin(phoneCode)
  },
  confirmWechatAvatar() {
    const phoneCode = this.data.pendingWechatPhoneCode
    if (!phoneCode) return
    if (!this.data.wechatAvatar) {
      wx.showToast({ title: "请先选择微信头像", icon: "none" })
      return
    }
    this.continueWechatLogin(phoneCode)
  },
  closeWechatAvatarDialog() {
    this.setData({
      showWechatAvatarPicker: false,
      pendingWechatPhoneCode: ""
    })
  },
  noop() {},
  prepareWechatProfile({ success }) {
    if (!this.data.importWechatAvatar) {
      success({ nickName: "微信用户", avatar: "" })
      return
    }
    this.readAvatarAsBase64(this.data.wechatAvatar, {
      success: (avatar) => success({ nickName: "微信用户", avatar }),
      fail: () => {
        wx.hideLoading()
        wx.showToast({ title: "头像读取失败，请重新选择", icon: "none" })
      }
    })
  },
  readAvatarAsBase64(filePath, callbacks) {
    if (!filePath || filePath.startsWith("data:image/")) {
      callbacks.success(filePath || "")
      return
    }
    if (filePath.startsWith("http://") && !filePath.startsWith("http://tmp/")) {
      callbacks.success(filePath)
      return
    }
    if (filePath.startsWith("https://")) {
      callbacks.success(filePath)
      return
    }
    wx.getFileSystemManager().readFile({
      filePath,
      encoding: "base64",
      success: (res) => callbacks.success(`data:image/jpeg;base64,${res.data}`),
      fail: callbacks.fail
    })
  },
  submitWechatLogin(code, phoneCode, profile = {}) {
    wx.request({
      url: "http://localhost:8080/api/twenty-mall/consumer/wechat-login",
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: {
        code,
        phoneCode,
        nickName: profile.nickName || "微信用户",
        avatar: profile.avatar || ""
      },
      success: (res) => {
        wx.hideLoading()
        const payload = res.data || {}
        if (payload.code !== "200" || !payload.data) {
          wx.showToast({ title: payload.message || "微信登录失败", icon: "none" })
          return
        }
        const account = payload.data
        saveDemoToken()
        savePrimaryAccount(account.accountNo)
        this.setData({
          showWechatAvatarPicker: false,
          pendingWechatPhoneCode: ""
        })
        saveConsumerProfile({
          nickname: account.displayName || "微信用户",
          phone: this.displayPhone(account.phone),
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
