import { fetchPrimaryProfileFromDatabase, fetchTwentyMallBindingsFromDatabase, getConsumerProfile, getPrimaryPhone } from "../../utils/auth"
import { enrichOrderDisplay } from "../../utils/order-display"

const API_BASE = "http://localhost:8080/api/demo-chat"
const AI_AVATAR = "/assets/avatars/ai-bot.png"

function formatMessageTime(value) {
  if (!value) return ""
  const text = String(value).replace("T", " ").replace(/\.\d+$/, "")
  const match = text.match(/^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?/)
  if (!match) return text
  const [, year, month, day, hour, minute, second = "00"] = match
  return `${year}.${Number(month)}.${Number(day)} ${hour.padStart(2, "0")}:${minute.padStart(2, "0")}:${second.padStart(2, "0")}`
}

function normalizeMessage(item) {
  const senderType = item.senderType || "AI"
  const isUser = senderType === "CONSUMER"
  const isStaff = senderType === "STAFF"
  return {
    id: item.id,
    role: isUser ? "user" : (isStaff ? "staff" : "ai"),
    speaker: isUser ? "我" : (isStaff ? "人工客服" : "AI客服"),
    avatarText: isUser ? "我" : (isStaff ? "人" : "AI"),
    time: formatMessageTime(item.createdAt),
    content: item.content
  }
}

function formatNow() {
  const now = new Date()
  return `${now.getFullYear()}.${now.getMonth() + 1}.${now.getDate()} ${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}:${String(now.getSeconds()).padStart(2, "0")}`
}

Page({
  data: {
    inputValue: "",
    mode: "AI",
    platformBound: false,
    orders: [],
    activeOrderNo: "",
    consultingOrder: null,
    messages: [],
    scrollTarget: "",
    lastMessageKey: "",
    consumerAvatar: "",
    merchantAvatar: ""
  },
  onLoad() {
    this.loadConsumerAvatar()
    this.applyPlatformBinding()
  },
  onShow() {
    this.applyPlatformBinding()
    this.startPolling()
  },
  onHide() {
    this.stopPolling()
  },
  onUnload() {
    this.stopPolling()
  },
  onInput(e) {
    this.setData({ inputValue: e.detail.value })
  },
  applyPlatformBinding() {
    fetchTwentyMallBindingsFromDatabase({
      success: (bindings) => this.applyBindings(bindings),
      fail: (bindings) => this.applyBindings(bindings)
    })
  },
  applyBindings(bindings) {
    if (!bindings.length) {
      this.setData({
        platformBound: false,
        orders: [],
        activeOrderNo: "",
        consultingOrder: null,
        messages: [],
        inputValue: "",
        mode: "AI"
      })
      return
    }
    const requests = bindings.map((binding) => new Promise((resolve) => {
      wx.request({
        url: `http://localhost:8080/api/twenty-mall/consumer/orders?accountNo=${binding.accountNo}`,
        success: (res) => {
          const list = (res.data && res.data.data) || []
          resolve(list.map((item) => enrichOrderDisplay({
            no: item.no,
            title: item.title,
            status: item.status,
            afterSale: item.afterSale,
            platform: "20商城",
            accountNo: binding.accountNo,
            merchantAccountNo: item.merchantAccountNo || "",
            merchantPrimaryAccountNo: item.merchantPrimaryAccountNo || "",
            merchant: item.merchant,
            price: item.price,
            image: item.image,
            spec: item.spec,
            service: item.afterSale === "未申请" ? "可申请售后" : "售后处理中"
          })))
        },
        fail: () => resolve([])
      })
    }))
    Promise.all(requests).then((result) => {
      const nextOrders = result.reduce((all, list) => all.concat(list), [])
      if (!nextOrders.length) {
        this.setData({
          platformBound: true,
          orders: [],
          activeOrderNo: "",
          consultingOrder: null,
          messages: []
        })
        return
      }
      const pendingOrderNo = wx.getStorageSync("pendingChatOrderNo")
      const currentOrderStillExists = nextOrders.some((item) => item.no === this.data.activeOrderNo)
      const activeOrder = nextOrders.find((item) => item.no === pendingOrderNo)
        || (currentOrderStillExists ? nextOrders.find((item) => item.no === this.data.activeOrderNo) : null)
        || nextOrders[0]
      if (pendingOrderNo) {
        wx.removeStorageSync("pendingChatOrderNo")
      }
      if (!currentOrderStillExists && this.data.activeOrderNo) {
        wx.removeStorageSync(`chatActiveOrderNo:${this.data.activeOrderNo}`)
      }
      this.setData({
        platformBound: true,
        orders: nextOrders,
        activeOrderNo: activeOrder.no,
        consultingOrder: activeOrder
      })
      this.loadMerchantAvatar(activeOrder.merchantPrimaryAccountNo || "")
      this.loadConversation(activeOrder.no)
      this.startPolling()
    })
  },
  loadConsumerAvatar() {
    const applyProfile = (profile) => {
      this.setData({ consumerAvatar: profile && profile.avatar ? profile.avatar : "" })
    }
    applyProfile(getConsumerProfile())
    fetchPrimaryProfileFromDatabase({
      success: applyProfile,
      fail: applyProfile
    })
  },
  loadMerchantAvatar(accountNo) {
    if (!accountNo) {
      this.setData({ merchantAvatar: "" })
      return
    }
    wx.request({
      url: `http://localhost:8080/api/twenty-mall/primary/profile?accountNo=${encodeURIComponent(accountNo)}&accountType=MERCHANT`,
      success: (res) => {
        const data = res.data && res.data.data
        this.setData({ merchantAvatar: data && data.avatar ? data.avatar : "" })
      },
      fail: () => this.setData({ merchantAvatar: "" })
    })
  },
  goOrderDetail() {
    if (!this.data.consultingOrder) return
    wx.navigateTo({ url: `/pages/product/index?no=${this.data.consultingOrder.no}` })
  },
  switchOrder(e) {
    const no = e.currentTarget.dataset.no
    this.doSwitchOrder(no)
  },
  openOrderSwitcher() {
    if (!this.data.orders.length) return
    wx.showActionSheet({
      itemList: this.data.orders.map((item) => `${item.title}｜${item.merchant}`.slice(0, 20)),
      success: (res) => {
        const order = this.data.orders[res.tapIndex]
        if (order) {
          this.doSwitchOrder(order.no)
        }
      }
    })
  },
  doSwitchOrder(no) {
    const order = this.data.orders.find((item) => item.no === no)
    if (!order) return
    this.setData({
      activeOrderNo: no,
      consultingOrder: order,
      mode: "AI",
      inputValue: "",
      messages: [],
      lastMessageKey: ""
    })
    this.loadMerchantAvatar(order.merchantPrimaryAccountNo || "")
    this.stopPolling()
    this.loadConversation(no)
    this.startPolling()
  },
  goBind() {
    wx.switchTab({ url: "/pages/home/index" })
  },
  sendMessage() {
    if (!this.data.platformBound || !this.data.activeOrderNo) {
      wx.showToast({ title: "请先绑定电商平台", icon: "none" })
      return
    }
    const value = this.data.inputValue.trim()
    if (!value) return
    const wantsHuman = value.includes("人工") || value.includes("客服")
    const no = this.data.activeOrderNo
    const optimisticMessage = {
      id: `local-${Date.now()}`,
      role: "user",
      speaker: "我",
      avatarText: "我",
      avatar: this.data.consumerAvatar,
      time: formatNow(),
      content: value
    }
    this.setData({
      inputValue: "",
      mode: wantsHuman ? "人工" : this.data.mode,
      messages: this.data.messages.concat(optimisticMessage),
      lastMessageKey: `local:${optimisticMessage.id}:${value}`
    }, () => {
      this.scrollToBottom()
    })
    wx.request({
      url: `${API_BASE}/conversations/${no}/messages`,
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: {
        senderType: "CONSUMER",
        content: value
      },
      success: (res) => {
        const payload = res.data || {}
        if (payload.code !== "200") {
          wx.showToast({ title: payload.message || "消息发送失败", icon: "none" })
          this.setData({
            inputValue: value,
            messages: this.data.messages.filter((item) => item.id !== optimisticMessage.id),
            lastMessageKey: ""
          })
          return
        }
        if (wantsHuman) {
          this.transferToStaff(no)
          return
        }
        this.loadMessages(no)
      },
      fail: () => {
        wx.showToast({ title: "消息发送失败，请确认后端已启动", icon: "none" })
        this.setData({
          inputValue: value,
          messages: this.data.messages.filter((item) => item.id !== optimisticMessage.id),
          lastMessageKey: ""
        })
      }
    })
  },
  transferToStaff(orderNo = this.data.activeOrderNo) {
    wx.request({
      url: `${API_BASE}/conversations/${orderNo}/transfer`,
      method: "POST",
      success: (res) => {
        const payload = res.data || {}
        if (payload.code !== "200") {
          wx.showToast({ title: payload.message || "转人工失败", icon: "none" })
          return
        }
        if (this.data.activeOrderNo !== orderNo) return
        this.setData({ mode: "人工" })
        this.loadMessages(orderNo)
      },
      fail: () => {
        wx.showToast({ title: "转人工失败，请稍后重试", icon: "none" })
      }
    })
  },
  loadConversation(orderNo = this.data.activeOrderNo) {
    if (!this.data.platformBound || !orderNo) return
    wx.request({
      url: `${API_BASE}/conversations/${orderNo}`,
      success: (res) => {
        if (this.data.activeOrderNo !== orderNo) return
        const data = res.data && res.data.data
        if (data) {
          this.setData({ mode: data.status === "AGENT_SERVING" ? "人工" : "AI" })
        }
        this.loadMessages(orderNo)
      },
      fail: () => this.loadMessages(orderNo)
    })
  },
  loadMessages(orderNo = this.data.activeOrderNo) {
    if (!this.data.platformBound || !orderNo) return
    wx.request({
      url: `${API_BASE}/conversations/${orderNo}/messages`,
      success: (res) => {
        if (this.data.activeOrderNo !== orderNo) return
        const list = (res.data && res.data.data) || []
        const messages = list.map(normalizeMessage)
          .map((item) => ({
            ...item,
            avatar: this.messageAvatar(item)
          }))
        const latest = messages[messages.length - 1]
        const nextMessageKey = latest ? `${messages.length}:${latest.id || ""}:${latest.time || ""}:${latest.content || ""}` : "0"
        const shouldScroll = nextMessageKey !== this.data.lastMessageKey
        if (!shouldScroll) {
          return
        }
        const latestUserMessage = messages.filter((item) => item.role === "user" && item.time).pop()
        if (latestUserMessage) {
          wx.setStorageSync(`consumerLastConsultAt:${getPrimaryPhone()}`, latestUserMessage.time)
        }
        this.setData({
          messages,
          lastMessageKey: nextMessageKey
        }, () => {
          if (shouldScroll) {
            this.scrollToBottom()
          }
        })
      }
    })
  },
  messageAvatar(message) {
    if (message.role === "ai") return AI_AVATAR
    if (message.role === "staff") return this.data.merchantAvatar
    return this.data.consumerAvatar
  },
  scrollToBottom() {
    this.setData({ scrollTarget: "" }, () => {
      wx.nextTick(() => {
        this.setData({ scrollTarget: "chat-bottom" })
      })
    })
  },
  startPolling() {
    this.stopPolling()
    if (!this.data.platformBound || !this.data.activeOrderNo) return
    this.pollingTimer = setInterval(() => this.loadConversation(this.data.activeOrderNo), 2500)
  },
  stopPolling() {
    if (this.pollingTimer) {
      clearInterval(this.pollingTimer)
      this.pollingTimer = null
    }
  }
})
