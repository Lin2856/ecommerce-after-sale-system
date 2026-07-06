import { fetchLocalPlatformBindingsFromDatabase, fetchPrimaryProfileFromDatabase, getConsumerProfile, getLocalPlatformConfig, getPrimaryPhone } from "../../utils/auth"
import { enrichOrderDisplay } from "../../utils/order-display"

const API_BASE = "http://localhost:8080/api/demo-chat"
const AI_AVATAR = "/assets/avatars/ai-bot.png"
const LOCAL_PLATFORM_CODES = ["TWENTY_MALL", "YUEGOU_MARKET"]

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
  const content = item.content || ""
  return {
    id: item.id,
    role: isUser ? "user" : (isStaff ? "staff" : "ai"),
    speaker: isUser ? "我" : (isStaff ? "人工客服" : "AI客服"),
    avatarText: isUser ? "我" : (isStaff ? "人" : "AI"),
    time: formatMessageTime(item.createdAt),
    content,
    showTransfer: !isUser && !isStaff && shouldShowTransferButton(content)
  }
}

function shouldShowTransferButton(content) {
  return /转人工|人工客服|人工处理|人工协助|联系人工|接入人工|无法直接|无法确认|不能直接|不能代替|需要人工|建议.*人工|平台管理员|商家进一步处理/.test(content || "")
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
    displayMessages: [],
    messageOrderNo: "",
    scrollTarget: "",
    scrollTop: 0,
    lastMessageKey: "",
    consumerAvatar: "",
    merchantAvatar: "",
    orderSwitcherVisible: false
  },
  onLoad() {
    this.loadConsumerAvatar()
    this.applyPlatformBinding()
  },
  onShow() {
    if (typeof this.getTabBar === "function" && this.getTabBar()) {
      this.getTabBar().setData({ selected: 2 })
    }
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
    const tasks = LOCAL_PLATFORM_CODES.map((platformCode) => new Promise((resolve) => {
      const config = getLocalPlatformConfig(platformCode)
      fetchLocalPlatformBindingsFromDatabase(platformCode, {
        success: (bindings) => resolve((bindings || []).map((binding) => ({
          ...binding,
          platformCode,
          platformName: config.name,
          apiPrefix: config.apiPrefix
        }))),
        fail: (bindings) => resolve((bindings || []).map((binding) => ({
          ...binding,
          platformCode,
          platformName: config.name,
          apiPrefix: config.apiPrefix
        })))
      })
    }))
    Promise.all(tasks).then((groups) => {
      this.applyBindings(groups.reduce((all, group) => all.concat(group), []))
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
        displayMessages: [],
        messageOrderNo: "",
        inputValue: "",
        mode: "AI"
      })
      return
    }
    const requests = bindings.map((binding) => new Promise((resolve) => {
      const platformName = binding.platformName || binding.platform || "电商平台"
      const apiPrefix = binding.apiPrefix || getLocalPlatformConfig(binding.platformCode).apiPrefix
      wx.request({
        url: `http://localhost:8080${apiPrefix}/consumer/orders?accountNo=${encodeURIComponent(binding.accountNo)}`,
        success: (res) => {
          const list = (res.data && res.data.data) || []
          resolve(list.map((item) => enrichOrderDisplay({
            no: item.no,
            title: item.title,
            status: item.status,
            afterSale: item.afterSale,
            platform: platformName,
            accountNo: binding.accountNo,
            platformCode: binding.platformCode,
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
          messages: [],
          displayMessages: [],
          messageOrderNo: ""
        })
        return
      }
      const pendingOrderNo = wx.getStorageSync("pendingChatOrderNo")
      const currentOrderStillExists = nextOrders.some((item) => item.no === this.data.activeOrderNo)
      const pendingOrder = nextOrders.find((item) => item.no === pendingOrderNo)
      if (pendingOrderNo && !pendingOrder) {
        wx.showToast({ title: "该订单暂未同步到聊天列表", icon: "none" })
      }
      const activeOrder = pendingOrder
        || (currentOrderStillExists ? nextOrders.find((item) => item.no === this.data.activeOrderNo) : null)
        || nextOrders[0]
      if (pendingOrderNo) {
        wx.removeStorageSync("pendingChatOrderNo")
      }
      if (!currentOrderStillExists && this.data.activeOrderNo) {
        wx.removeStorageSync(`chatActiveOrderNo:${this.data.activeOrderNo}`)
      }
      const orderChanged = activeOrder.no !== this.data.activeOrderNo || this.data.messageOrderNo !== activeOrder.no
      this.setData({
        platformBound: true,
        orders: nextOrders,
        activeOrderNo: activeOrder.no,
        consultingOrder: activeOrder,
        messages: orderChanged ? [] : this.data.messages,
        displayMessages: orderChanged ? [] : this.data.messages,
        messageOrderNo: orderChanged ? activeOrder.no : this.data.messageOrderNo,
        lastMessageKey: orderChanged ? "" : this.data.lastMessageKey
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
    if (!this.data.orders.length) {
      wx.showToast({ title: "暂无可切换订单", icon: "none" })
      return
    }
    this.setData({ orderSwitcherVisible: true })
  },
  closeOrderSwitcher() {
    this.setData({ orderSwitcherVisible: false })
  },
  noop() {
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
      displayMessages: [],
      messageOrderNo: no,
      lastMessageKey: "",
      orderSwitcherVisible: false
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
      displayMessages: this.data.messages.concat(optimisticMessage),
      messageOrderNo: no,
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
            displayMessages: this.data.displayMessages.filter((item) => item.id !== optimisticMessage.id),
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
          displayMessages: this.data.displayMessages.filter((item) => item.id !== optimisticMessage.id),
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
  transferFromAiMessage(e) {
    const orderNo = e.currentTarget.dataset.orderNo || this.data.activeOrderNo
    this.transferToStaff(orderNo)
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
    const requestSeq = (this.messageRequestSeq || 0) + 1
    this.messageRequestSeq = requestSeq
    wx.request({
      url: `${API_BASE}/conversations/${orderNo}/messages`,
      success: (res) => {
        if (requestSeq !== this.messageRequestSeq) return
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
          displayMessages: messages,
          messageOrderNo: orderNo,
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
    const nextScrollTop = (this.data.scrollTop || 0) + 100000
    this.setData({ scrollTarget: "", scrollTop: nextScrollTop }, () => {
      wx.nextTick(() => {
        this.setData({ scrollTarget: "chat-bottom" })
        setTimeout(() => {
          this.setData({ scrollTop: nextScrollTop + 100000, scrollTarget: "chat-bottom" })
        }, 80)
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
