import { orders } from "../../utils/mock"
import { getLocalPlatformConfig } from "../../utils/auth"
import { enrichOrderDisplay } from "../../utils/order-display"

function resolveOrderPlatform(orderNo) {
  if (String(orderNo || "").startsWith("YG")) {
    return { code: "YUEGOU_MARKET", fallbackMerchant: "悦购集市店铺" }
  }
  return { code: "TWENTY_MALL", fallbackMerchant: "万象商城店铺" }
}

function isLocalPlatformOrderNo(orderNo) {
  return /^(TM|WX|YG)\d+/i.test(String(orderNo || ""))
}

Page({
  data: {
    product: null,
    afterSaleDetail: null,
    afterSaleDetailVisible: false,
    returnTrackingNo: "",
    disputeDialogVisible: false,
    disputeReasonText: "",
    disputeImages: [],
    afterSaleApplyVisible: false,
    afterSaleApplyMode: "create",
    afterSaleTypeOptions: [
      { label: "仅退款", value: "REFUND_ONLY", icon: "款" },
      { label: "退货退款", value: "RETURN_REFUND", icon: "退" },
      { label: "价保", value: "PRICE_PROTECTION", icon: "保" },
      { label: "换货", value: "EXCHANGE", icon: "换" }
    ],
    selectedAfterSaleType: "RETURN_REFUND",
    selectedAfterSaleLabel: "退货退款",
    reasonOptions: ["商品质量问题", "商品破损/污渍", "实物与描述不符", "少件/漏发", "价格保护", "其他问题"],
    currentReasonOptions: ["商品质量问题", "商品破损/污渍", "实物与描述不符", "少件/漏发", "其他问题"],
    reasonIndex: 0,
    reasonDialogVisible: false,
    reasonForm: null,
    reasonText: "",
    reasonTextLength: 0,
    reasonImages: [],
    reviewVisible: false,
    productReviewScore: 5,
    merchantReviewScore: 5,
    productReviewText: "",
    merchantReviewText: "",
    reviewImages: [],
    reviewDetailVisible: false,
    reviewDetail: null,
    apiBase: "http://localhost:8080/api/twenty-mall",
    platformName: "万象商城",
    productReviewStars: [
      { value: 1, active: true },
      { value: 2, active: true },
      { value: 3, active: true },
      { value: 4, active: true },
      { value: 5, active: true }
    ],
    merchantReviewStars: [
      { value: 1, active: true },
      { value: 2, active: true },
      { value: 3, active: true },
      { value: 4, active: true },
      { value: 5, active: true }
    ]
  },
  onLoad(options) {
    const platform = resolveOrderPlatform(options.no)
    const config = getLocalPlatformConfig(platform.code)
    const apiBase = `http://localhost:8080${config.apiPrefix}`
    this.setData({
      apiBase,
      platformName: config.name
    })
    if (options.no && isLocalPlatformOrderNo(options.no)) {
      wx.request({
        url: `${apiBase}/consumer/orders/detail?orderNo=${encodeURIComponent(options.no)}`,
        success: (res) => {
          const item = res.data && res.data.data
          if (item) {
            const product = enrichOrderDisplay({
              no: item.no,
              title: item.title,
              status: item.status,
              afterSale: this.afterSaleStatusText(item.afterSale),
              platform: config.name,
              merchant: item.merchant || platform.fallbackMerchant,
              price: item.price,
              image: item.image,
              spec: item.spec,
              orderedAt: item.orderedAt,
              deliveredAt: item.deliveredAt,
              policyTags: item.policyTags,
              reviewed: !!item.reviewed,
              service: this.afterSaleStatusText(item.afterSale) === "未申请" ? "可申请售后" : "售后处理中"
            })
            this.setData({ product, afterSaleDetail: null })
            if (product.afterSale && product.afterSale !== "未申请") {
              this.loadAfterSaleDetail(product.no)
            }
          }
        }
      })
      return
    }
    const product = enrichOrderDisplay(orders.find((item) => item.no === options.no) || orders[0])
    this.setData({ product, afterSaleDetail: null })
  },
  currentApiBase() {
    return this.data.apiBase || "http://localhost:8080/api/twenty-mall"
  },
  handleAfterSalePrimary() {
    if (!this.data.product) return
    if (this.hasAppliedAfterSale()) {
      this.loadAfterSaleDetail(this.data.product.no)
      this.setData({ afterSaleDetailVisible: true })
      return
    }
    this.submitAfterSale(false)
  },
  modifyAfterSale() {
    const status = this.data.product && this.data.product.afterSale
    if (this.isAfterSaleFinalStatus(status)) {
      wx.showToast({ title: "售后已完成，不能修改", icon: "none" })
      return
    }
    this.submitAfterSale(true)
  },
  closeAfterSaleDetail() {
    this.setData({ afterSaleDetailVisible: false, returnTrackingNo: "" })
  },
  submitAfterSale(isModify) {
    if (!this.data.product) return
    this.setData({
      afterSaleApplyVisible: true,
      afterSaleApplyMode: isModify ? "modify" : "create",
      selectedAfterSaleType: "RETURN_REFUND",
      selectedAfterSaleLabel: "退货退款",
      currentReasonOptions: this.getReasonOptionsByAfterSaleType("RETURN_REFUND"),
      reasonIndex: 0,
      reasonText: "",
      reasonTextLength: 0,
      reasonImages: []
    })
  },
  closeAfterSaleApply() {
    this.setData({
      afterSaleApplyVisible: false,
      afterSaleApplyMode: "create",
      selectedAfterSaleType: "RETURN_REFUND",
      selectedAfterSaleLabel: "退货退款",
      currentReasonOptions: this.getReasonOptionsByAfterSaleType("RETURN_REFUND"),
      reasonIndex: 0,
      reasonText: "",
      reasonTextLength: 0,
      reasonImages: []
    })
  },
  selectAfterSaleType(event) {
    const value = event.currentTarget.dataset.value
    const selected = this.data.afterSaleTypeOptions.find((item) => item.value === value) || this.data.afterSaleTypeOptions[1]
    const currentReasonOptions = this.getReasonOptionsByAfterSaleType(selected.value)
    this.setData({
      selectedAfterSaleType: selected.value,
      selectedAfterSaleLabel: selected.label,
      currentReasonOptions,
      reasonIndex: 0
    })
  },
  getReasonOptionsByAfterSaleType(afterSaleType) {
    if (afterSaleType === "PRICE_PROTECTION") {
      return ["价格保护"]
    }
    return this.data.reasonOptions.filter((item) => item !== "价格保护")
  },
  onReasonOptionChange(event) {
    this.setData({ reasonIndex: Number(event.detail.value || 0) })
  },
  submitAfterSaleApply() {
    const typeValue = this.data.selectedAfterSaleType
    const label = this.data.selectedAfterSaleLabel
    const currentReasonOptions = this.getReasonOptionsByAfterSaleType(typeValue)
    const reason = currentReasonOptions[this.data.reasonIndex] || currentReasonOptions[0] || "商品质量问题"
    const detail = this.data.reasonText.trim()
    if (!detail) {
      wx.showToast({ title: "请填写问题描述", icon: "none" })
      return
    }
    const backendTypeMap = {
      REFUND_ONLY: "REFUND_ONLY",
      RETURN_REFUND: "RETURN_REFUND",
      PRICE_PROTECTION: "PRICE_PROTECTION",
      EXCHANGE: "EXCHANGE"
    }
    const reasonTypeMap = {
      PRICE_PROTECTION: "PRICE_PROTECTION"
    }
    this.setData({ afterSaleApplyVisible: false })
    this.doSubmitAfterSale(
      label,
      backendTypeMap[typeValue] || "RETURN_REFUND",
      reasonTypeMap[typeValue] || "PRODUCT_QUALITY",
      `${reason}：${detail}`,
      this.data.afterSaleApplyMode === "modify",
      this.data.reasonImages
    )
  },
  cancelAfterSale() {
    if (!this.data.product) return
    wx.showModal({
      title: "取消售后申请",
      content: "取消后商家端将不再显示该售后申请，确认取消吗？",
      confirmText: "确认取消",
      confirmColor: "#d92d20",
      success: (modalRes) => {
        if (!modalRes.confirm) return
        wx.showLoading({ title: "取消中" })
        wx.request({
          url: `${this.currentApiBase()}/consumer/after-sales/cancel`,
          method: "POST",
          header: { "Content-Type": "application/json" },
          data: { orderNo: this.data.product.no },
          success: (response) => {
            const payload = response.data || {}
            if (payload.code !== "200") {
              wx.showToast({ title: payload.message || "取消失败", icon: "none" })
              return
            }
            const product = {
              ...this.data.product,
              afterSale: "未申请",
              service: "可申请售后"
            }
            wx.removeStorageSync(`afterSaleDetail:${product.no}`)
            this.setData({
              product,
              afterSaleDetail: null,
              afterSaleDetailVisible: false,
              afterSaleApplyVisible: false,
              afterSaleApplyMode: "create"
            })
            wx.showToast({ title: "售后已取消", icon: "success" })
          },
          fail: () => {
            wx.showToast({ title: "请先启动后端服务", icon: "none" })
          },
          complete: () => {
            wx.hideLoading()
          }
        })
      }
    })
  },
  requestAfterSaleReason(type, afterSaleType, reasonType, isModify) {
    this.setData({
      reasonDialogVisible: true,
      reasonForm: { type, afterSaleType, reasonType, isModify },
      reasonText: "",
      reasonImages: []
    })
  },
  onReasonInput(event) {
    const value = event.detail.value || ""
    this.setData({ reasonText: value, reasonTextLength: value.length })
  },
  chooseReasonImage() {
    const remainCount = 3 - this.data.reasonImages.length
    if (remainCount <= 0) {
      wx.showToast({ title: "最多上传3张照片", icon: "none" })
      return
    }
    const handleFiles = (paths) => {
      this.prepareEvidenceImages(paths).then((images) => {
        this.setData({
          reasonImages: this.data.reasonImages.concat(images).slice(0, 3)
        })
      })
    }
    if (wx.chooseMedia) {
      wx.chooseMedia({
        count: remainCount,
        mediaType: ["image"],
        sourceType: ["album", "camera"],
        success: (res) => handleFiles((res.tempFiles || []).map((item) => item.tempFilePath))
      })
      return
    }
    wx.chooseImage({
      count: remainCount,
      sourceType: ["album", "camera"],
      success: (res) => handleFiles(res.tempFilePaths || [])
    })
  },
  prepareEvidenceImages(paths) {
    return Promise.all(paths.map((path) => this.compressImage(path).then((nextPath) => this.convertImageToDataUrl(nextPath))))
  },
  compressImage(path) {
    return new Promise((resolve) => {
      if (!wx.compressImage || !path) {
        resolve(path)
        return
      }
      wx.compressImage({
        src: path,
        quality: 35,
        success: (res) => resolve(res.tempFilePath || path),
        fail: () => resolve(path)
      })
    })
  },
  convertImageToDataUrl(path) {
    return new Promise((resolve) => {
      if (!path || path.startsWith("data:image")) {
        resolve(path)
        return
      }
      wx.getFileSystemManager().readFile({
        filePath: path,
        encoding: "base64",
        success: (res) => {
          const ext = path.toLowerCase().includes(".png") ? "png" : "jpeg"
          resolve(`data:image/${ext};base64,${res.data}`)
        },
        fail: () => resolve(path)
      })
    })
  },
  removeReasonImage(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.setData({
      reasonImages: this.data.reasonImages.filter((_, currentIndex) => currentIndex !== index)
    })
  },
  closeReasonDialog() {
    this.setData({
      reasonDialogVisible: false,
      reasonForm: null,
      reasonText: "",
      reasonImages: []
    })
  },
  submitReasonDialog() {
    const form = this.data.reasonForm
    const reason = this.data.reasonText.trim()
    if (!form) return
    if (!reason) {
      wx.showToast({ title: "请输入申请原因", icon: "none" })
      return
    }
    this.setData({ reasonDialogVisible: false })
    this.doSubmitAfterSale(form.type, form.afterSaleType, form.reasonType, reason, form.isModify, this.data.reasonImages)
  },
  doSubmitAfterSale(type, afterSaleType, reasonType, description, isModify, evidenceImages = []) {
    if (!this.data.product) return
        wx.showLoading({ title: "提交中" })
        wx.request({
          url: `${this.currentApiBase()}/consumer/after-sales`,
          method: "POST",
          header: { "Content-Type": "application/json" },
          data: {
            orderNo: this.data.product.no,
            afterSaleType,
            reasonType,
            description,
            evidenceImages
          },
          success: (response) => {
            const payload = response.data || {}
            if (payload.code !== "200") {
              wx.showToast({ title: payload.message || "提交失败", icon: "none" })
              return
            }
            const data = payload.data || {}
            const product = {
              ...this.data.product,
              afterSale: this.afterSaleStatusText(data.status) || "待审核",
              service: "售后处理中"
            }
            const afterSaleDetail = {
              orderNo: product.no,
              productName: product.title,
              merchantName: product.merchant,
              status: product.afterSale,
              type,
              reason: description,
              consumerTip: this.buildAfterSaleConsumerTip({
                status: data.status || "PENDING_REVIEW",
                statusText: product.afterSale,
                type
              }),
              evidenceImages: this.normalizeEvidenceImages(data.evidenceImages || evidenceImages),
              returnTrackingNo: data.returnTrackingNo || "",
              returnShippedAt: data.returnShippedAt || "",
              appliedAt: data.createdAt || this.formatNow()
            }
            wx.setStorageSync(`afterSaleDetail:${product.no}`, afterSaleDetail)
            this.setData({
              product,
              afterSaleDetail,
              reasonForm: null,
              reasonText: "",
              reasonImages: []
            })
            wx.showToast({ title: isModify ? "售后已修改" : "售后已提交", icon: "success" })
          },
          fail: () => {
            wx.showToast({ title: "请先启动后端服务", icon: "none" })
          },
          complete: () => {
            wx.hideLoading()
          }
        })
  },
  hasAppliedAfterSale() {
    return this.data.product && this.data.product.afterSale && this.data.product.afterSale !== "未申请"
  },
  loadAfterSaleDetail(orderNo) {
    wx.request({
      url: `${this.currentApiBase()}/consumer/after-sales/detail?orderNo=${encodeURIComponent(orderNo)}`,
      success: (res) => {
        const payload = res.data || {}
        if (payload.code !== "200" || !payload.data) {
          this.setData({ afterSaleDetail: null })
          return
        }
        const data = payload.data
        const afterSaleTypeText = this.afterSaleTypeText(data.afterSaleType)
        const statusText = this.afterSaleDetailStatusText(data.status, data.afterSaleType)
        const consumerTip = this.buildAfterSaleConsumerTip({
          status: data.status,
          statusText,
          type: afterSaleTypeText,
          reviewOpinion: data.reviewOpinion || ""
        })
        const disputeResult = this.buildDisputeResultText({
          type: afterSaleTypeText,
          disputeStatus: data.disputeStatus || "",
          disputeAdminResult: data.disputeAdminResult || "",
          disputeAdminNote: data.disputeAdminNote || ""
        })
        this.setData({
          afterSaleDetail: {
            orderNo: data.orderNo,
            productName: data.productName,
            merchantName: data.shopName,
            status: statusText,
            type: afterSaleTypeText,
            reason: data.description,
            reviewOpinion: data.reviewOpinion || "",
            consumerTip,
            evidenceImages: this.normalizeEvidenceImages(data.evidenceImages || []),
            returnTrackingNo: data.returnTrackingNo || "",
            returnShippedAt: data.returnShippedAt || "",
            disputeStatus: data.disputeStatus || "",
            disputeAdminResult: data.disputeAdminResult || "",
            disputeAdminNote: data.disputeAdminNote || "",
            disputeResultText: disputeResult.text,
            disputeResultTip: disputeResult.tip,
            appliedAt: data.createdAt
          },
          product: this.data.product ? { ...this.data.product, afterSale: statusText } : this.data.product
        })
      }
    })
  },
  onReturnTrackingInput(event) {
    this.setData({ returnTrackingNo: event.detail.value })
  },
  submitReturnTracking() {
    if (!this.data.product) return
    const trackingNo = this.data.returnTrackingNo.trim()
    if (!trackingNo) {
      wx.showToast({ title: "请输入快递单号", icon: "none" })
      return
    }
    wx.showLoading({ title: "提交中" })
    wx.request({
      url: `${this.currentApiBase()}/consumer/after-sales/return-shipping`,
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: {
        orderNo: this.data.product.no,
        trackingNo
      },
      success: (response) => {
        const payload = response.data || {}
        if (payload.code !== "200") {
          wx.showToast({ title: payload.message || "提交失败", icon: "none" })
          return
        }
        const data = payload.data || {}
        const product = {
          ...this.data.product,
          afterSale: this.afterSaleStatusText(data.status),
          service: "售后处理中"
        }
        this.setData({
          product,
          returnTrackingNo: "",
          afterSaleDetail: {
            ...this.data.afterSaleDetail,
            status: product.afterSale,
            returnTrackingNo: data.returnTrackingNo || trackingNo,
            returnShippedAt: data.returnShippedAt || this.formatNow(),
            consumerTip: this.buildAfterSaleConsumerTip({
              status: data.status || "RETURN_SHIPPED",
              statusText: product.afterSale,
              type: this.data.afterSaleDetail.type
            })
          }
        })
        wx.showToast({ title: "快递单号已同步", icon: "success" })
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      },
      complete: () => {
        wx.hideLoading()
      }
    })
  },
  openDisputeDialog() {
    if (this.data.afterSaleDetail && this.data.afterSaleDetail.disputeStatus) {
      wx.showToast({ title: "该订单已申请过平台介入", icon: "none" })
      return
    }
    this.setData({
      disputeDialogVisible: true,
      disputeReasonText: "",
      disputeImages: []
    })
  },
  closeDisputeDialog() {
    this.setData({
      disputeDialogVisible: false,
      disputeReasonText: "",
      disputeImages: []
    })
  },
  onDisputeReasonInput(event) {
    this.setData({ disputeReasonText: event.detail.value })
  },
  chooseDisputeImage() {
    const remainCount = 3 - this.data.disputeImages.length
    if (remainCount <= 0) {
      wx.showToast({ title: "最多上传3张照片", icon: "none" })
      return
    }
    const handleFiles = (paths) => {
      this.prepareEvidenceImages(paths).then((images) => {
        this.setData({
          disputeImages: this.data.disputeImages.concat(images).slice(0, 3)
        })
      })
    }
    if (wx.chooseMedia) {
      wx.chooseMedia({
        count: remainCount,
        mediaType: ["image"],
        sourceType: ["album", "camera"],
        success: (res) => handleFiles((res.tempFiles || []).map((item) => item.tempFilePath))
      })
      return
    }
    wx.chooseImage({
      count: remainCount,
      sourceType: ["album", "camera"],
      success: (res) => handleFiles(res.tempFilePaths || [])
    })
  },
  removeDisputeImage(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.setData({
      disputeImages: this.data.disputeImages.filter((_, currentIndex) => currentIndex !== index)
    })
  },
  submitDisputeDialog() {
    if (!this.data.product) return
    if (this.data.afterSaleDetail && this.data.afterSaleDetail.disputeStatus) {
      wx.showToast({ title: "该订单已申请过平台介入", icon: "none" })
      this.closeDisputeDialog()
      return
    }
    const reason = this.data.disputeReasonText.trim()
    if (!reason) {
      wx.showToast({ title: "请填写平台介入原因", icon: "none" })
      return
    }
    wx.showLoading({ title: "提交中" })
    wx.request({
      url: `${this.currentApiBase()}/consumer/after-sales/disputes`,
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: {
        orderNo: this.data.product.no,
        reason,
        evidenceImages: this.data.disputeImages
      },
      success: (response) => {
        const payload = response.data || {}
        if (payload.code !== "200") {
          wx.showToast({ title: payload.message || "提交失败", icon: "none" })
          return
        }
        this.setData({
          disputeDialogVisible: false,
          disputeReasonText: "",
          disputeImages: [],
          afterSaleDetail: {
            ...this.data.afterSaleDetail,
            disputeStatus: "待审核"
          }
        })
        wx.showToast({ title: "已提交平台介入", icon: "success" })
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      },
      complete: () => {
        wx.hideLoading()
      }
    })
  },
  normalizeEvidenceImages(images) {
    return (images || []).map((image) => {
      if (typeof image === "string" && image.startsWith("/api/")) {
        return `http://localhost:8080${image}`
      }
      return image
    })
  },
  afterSaleTypeText(value) {
    const map = {
      REFUND_ONLY: "仅退款",
      RETURN_REFUND: "退货退款",
      PRICE_PROTECTION: "价保",
      EXCHANGE: "换货"
    }
    return map[value] || value || ""
  },
  afterSaleStatusText(value) {
    const map = {
      PENDING_REVIEW: "待审核",
      PROCESSING: "处理中",
      WAITING_RETURN: "商家已同意退款，请寄回商品",
      RETURN_SHIPPED: "用户已寄回商品",
      REJECTED: "已拒绝",
      COMPLETED: "已完成",
      CLOSED: "已关闭"
    }
    return map[value] || value || ""
  },
  afterSaleDetailStatusText(status, afterSaleType) {
    if (afterSaleType === "PRICE_PROTECTION" && (status === "COMPLETED" || status === "WAITING_RETURN" || status === "PROCESSING")) {
      return "商家已同意价保申请，差价已自动退回你的账户"
    }
    return this.afterSaleStatusText(status)
  },
  buildAfterSaleConsumerTip(detail) {
    const status = detail.status || ""
    const statusText = detail.statusText || ""
    const type = detail.type || "售后"
    const reviewOpinion = detail.reviewOpinion || ""
    if (status === "PENDING_REVIEW") {
      return `你的${type}申请已提交，商家将在规定时间内审核处理。`
    }
    if (status === "REJECTED") {
      const reason = reviewOpinion.replace(/^审核拒绝：/, "").trim()
      if (type === "价保") {
        return reason
          ? `商家未同意本次价保申请，拒绝原因：${reason}。如你仍有疑问，可以联系商家进一步沟通。`
          : "商家未同意本次价保申请。如你仍有疑问，可以联系商家进一步沟通。"
      }
      return reason
        ? `商家未同意本次${type}申请，拒绝原因：${reason}。如你仍有异议，可以申请平台介入。`
        : `商家未同意本次${type}申请。如你仍有异议，可以申请平台介入。`
    }
    if (type === "价保" && statusText === "商家已同意价保申请，差价已自动退回你的账户") {
      return "商家已同意价保申请，差价已自动退回你的账户。"
    }
    if (status === "WAITING_RETURN") {
      return type === "换货"
        ? "商家已同意换货申请，请按页面提示寄回商品，商家收货验收后将为你安排换货。"
        : "商家已同意退货退款申请，请按页面提示寄回商品，商家收货验收后将继续处理退款。"
    }
    if (status === "RETURN_SHIPPED") {
      return "退货快递单号已提交，商家收到商品并验收后会继续处理。"
    }
    if (status === "PROCESSING") {
      return type === "仅退款"
        ? "商家已同意仅退款申请，退款将按原支付方式退回你的账户。"
        : `商家已同意本次${type}申请，正在为你处理。`
    }
    if (status === "COMPLETED") {
      if (type === "仅退款") {
        return "商家已同意仅退款申请，退款已退回你的账户。"
      }
      if (type === "退货退款") {
        return "商家已完成退货退款处理，退款已退回你的账户。"
      }
      if (type === "换货") {
        return "商家已完成换货处理，请留意新商品物流信息。"
      }
      return "本次售后已完成。"
    }
    if (status === "CLOSED") {
      return "本次售后已关闭，如仍有问题可以重新联系商家确认。"
    }
    return `本次${type}申请正在处理，请留意后续结果。`
  },
  isAfterSaleFinalStatus(status) {
    return ["已完成", "已关闭", "商家已同意价保申请，差价已自动退回你的账户"].includes(status)
  },
  buildDisputeResultText(detail) {
    const status = detail.disputeStatus || ""
    const result = detail.disputeAdminResult || ""
    const note = detail.disputeAdminNote || ""
    const type = detail.type || "售后申请"
    if (!status || status === "待审核") {
      return { text: "", tip: "" }
    }
    if (result === "超时自动退款" || note.includes("超时未处理")) {
      return {
        text: "超时未处理，平台自动退款",
        tip: "平台在规定时效内未收到处理结果，系统已自动退款给消费者。"
      }
    }
    if (result === "支持消费者" || result === "部分退款") {
      return {
        text: `平台支持消费者，同意${type}`,
        tip: result === "部分退款"
          ? "平台已裁定支持消费者，并按管理员确认的金额完成部分退款。"
          : `平台已裁定支持消费者，本次${type}处理已完成。`
      }
    }
    if (result === "支持商家") {
      return {
        text: `平台支持商家，不同意${type}`,
        tip: `平台已裁定支持商家，本次${type}申请不再继续退款处理。`
      }
    }
    return {
      text: note || result || status,
      tip: note || "平台已完成本次争议订单处理。"
    }
  },
  formatNow() {
    const date = new Date()
    const pad = (value) => String(value).padStart(2, "0")
    return `${date.getFullYear()}.${date.getMonth() + 1}.${date.getDate()} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
  },
  contactMerchant() {
    if (!this.data.product) return
    wx.setStorageSync("pendingChatOrderNo", this.data.product.no)
    wx.switchTab({ url: "/pages/chat/index" })
  },
  openReviewDialog() {
    if (this.data.product && this.data.product.reviewed) {
      this.loadReviewDetail()
      return
    }
    this.setData({
      reviewVisible: true,
      productReviewScore: 5,
      merchantReviewScore: 5,
      productReviewText: "",
      merchantReviewText: "",
      reviewImages: [],
      productReviewStars: this.buildStars(5),
      merchantReviewStars: this.buildStars(5)
    })
  },
  loadReviewDetail() {
    if (!this.data.product) return
    wx.showLoading({ title: "加载中" })
    wx.request({
      url: `${this.currentApiBase()}/consumer/reviews/detail?orderNo=${encodeURIComponent(this.data.product.no)}`,
      success: (response) => {
        const payload = response.data || {}
        if (payload.code !== "200" || !payload.data) {
          wx.showToast({ title: payload.message || "暂无评价详情", icon: "none" })
          return
        }
        const detail = payload.data
        this.setData({
          reviewDetailVisible: true,
          reviewDetail: {
            ...detail,
            imageUrls: this.normalizeEvidenceImages(detail.imageUrls || []),
            productStars: this.buildStars(Number(detail.productScore || 0)),
            serviceStars: this.buildStars(Number(detail.serviceScore || 0))
          }
        })
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      },
      complete: () => {
        wx.hideLoading()
      }
    })
  },
  closeReviewDetail() {
    this.setData({
      reviewDetailVisible: false,
      reviewDetail: null
    })
  },
  closeReviewDialog() {
    this.setData({ reviewVisible: false, reviewImages: [] })
  },
  setProductReviewScore(event) {
    const score = Number(event.currentTarget.dataset.score)
    this.setData({
      productReviewScore: score,
      productReviewStars: this.buildStars(score)
    })
  },
  setMerchantReviewScore(event) {
    const score = Number(event.currentTarget.dataset.score)
    this.setData({
      merchantReviewScore: score,
      merchantReviewStars: this.buildStars(score)
    })
  },
  onProductReviewInput(event) {
    this.setData({ productReviewText: event.detail.value })
  },
  onMerchantReviewInput(event) {
    this.setData({ merchantReviewText: event.detail.value })
  },
  chooseReviewImage() {
    const remainCount = 3 - this.data.reviewImages.length
    if (remainCount <= 0) {
      wx.showToast({ title: "最多上传3张照片", icon: "none" })
      return
    }
    const handleFiles = (paths) => {
      this.prepareEvidenceImages(paths).then((images) => {
        this.setData({
          reviewImages: this.data.reviewImages.concat(images).slice(0, 3)
        })
      })
    }
    if (wx.chooseMedia) {
      wx.chooseMedia({
        count: remainCount,
        mediaType: ["image"],
        sourceType: ["album", "camera"],
        success: (res) => handleFiles((res.tempFiles || []).map((file) => file.tempFilePath))
      })
      return
    }
    wx.chooseImage({
      count: remainCount,
      sourceType: ["album", "camera"],
      success: (res) => handleFiles(res.tempFilePaths || [])
    })
  },
  removeReviewImage(event) {
    const index = Number(event.currentTarget.dataset.index)
    this.setData({
      reviewImages: this.data.reviewImages.filter((_, currentIndex) => currentIndex !== index)
    })
  },
  submitReview() {
    const productContent = this.data.productReviewText.trim()
    const merchantContent = this.data.merchantReviewText.trim()
    if (!productContent) {
      wx.showToast({ title: "请输入产品质量评价", icon: "none" })
      return
    }
    if (!merchantContent) {
      wx.showToast({ title: "请输入商家服务评价", icon: "none" })
      return
    }
    wx.showLoading({ title: "提交中" })
    wx.request({
      url: `${this.currentApiBase()}/consumer/reviews`,
      method: "POST",
      header: { "Content-Type": "application/json" },
      data: {
        orderNo: this.data.product.no,
        productScore: this.data.productReviewScore,
        serviceScore: this.data.merchantReviewScore,
        productContent,
        merchantContent,
        imageUrls: this.data.reviewImages
      },
      success: (response) => {
        const payload = response.data || {}
        if (payload.code !== "200") {
          wx.showToast({ title: payload.message || "评价失败", icon: "none" })
          return
        }
        wx.showToast({ title: "评价已提交", icon: "success" })
        this.setData({
          reviewVisible: false,
          reviewImages: [],
          product: {
            ...this.data.product,
            reviewed: true
          }
        })
      },
      fail: () => {
        wx.showToast({ title: "请先启动后端服务", icon: "none" })
      },
      complete: () => {
        wx.hideLoading()
      }
    })
  },
  buildStars(score) {
    return [1, 2, 3, 4, 5].map((value) => ({
      value,
      active: value <= score
    }))
  }
})
