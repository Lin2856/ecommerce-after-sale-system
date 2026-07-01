import { fetchPrimaryProfileFromDatabase, getConsumerProfile, getPrimaryPhone, savePrimaryProfileToDatabase } from "../../utils/auth"

Page({
  data: {
    form: {
      nickname: "",
      avatar: ""
    },
    phone: "",
    saving: false
  },
  onLoad() {
    const profile = getConsumerProfile()
    const phone = getPrimaryPhone()
    this.setData({ phone: phone === "guest" ? "" : phone })
    if (profile) {
      this.setData({
        form: {
          nickname: profile.nickname || "",
          avatar: profile.avatar || this.data.form.avatar
        }
      })
    }
    fetchPrimaryProfileFromDatabase({
      success: (dbProfile) => {
        this.setData({
          form: {
            nickname: dbProfile.nickname || "",
            avatar: dbProfile.avatar || ""
          },
          phone: dbProfile.phone || (phone === "guest" ? "" : phone)
        })
      }
    })
  },
  onInput(e) {
    const field = e.currentTarget.dataset.field
    this.setData({ [`form.${field}`]: e.detail.value })
  },
  chooseAvatar() {
    wx.chooseMedia({
      count: 1,
      mediaType: ["image"],
      success: (res) => {
        const file = res.tempFiles && res.tempFiles[0]
        if (file && file.tempFilePath) {
          this.setData({ "form.avatar": file.tempFilePath })
        }
      },
      fail: () => {
        wx.showToast({ title: "暂未选择头像", icon: "none" })
      }
    })
  },
  saveProfile() {
    if (this.data.saving) return
    this.setData({ saving: true })
    savePrimaryProfileToDatabase(this.data.form, {
      success: () => {
        wx.showToast({ title: "资料已保存", icon: "success" })
        setTimeout(() => wx.navigateBack(), 500)
      },
      fail: (message) => {
        this.setData({ saving: false })
        wx.showToast({ title: message || "资料保存失败", icon: "none" })
      }
    })
  }
})
