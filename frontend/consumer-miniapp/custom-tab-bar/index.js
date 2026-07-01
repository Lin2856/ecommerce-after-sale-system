Component({
  data: {
    selected: 0,
    list: [
      {
        pagePath: "/pages/home/index",
        text: "首页",
        iconPath: "/assets/tabbar/home.png"
      },
      {
        pagePath: "/pages/order/index",
        text: "订单",
        iconPath: "/assets/tabbar/order.png"
      },
      {
        pagePath: "/pages/chat/index",
        text: "客服",
        iconPath: "/assets/tabbar/chat.png"
      },
      {
        pagePath: "/pages/user/index",
        text: "我的",
        iconPath: "/assets/tabbar/user.png"
      }
    ]
  },
  methods: {
    switchTab(e) {
      const { path, index } = e.currentTarget.dataset
      this.setData({ selected: Number(index) })
      wx.switchTab({ url: path })
    }
  }
})
