export function saveDemoToken() {
  wx.setStorageSync('miniapp_token', 'demo-token')
}

export function savePrimaryAccount(phone) {
  wx.setStorageSync("primaryAccount", { phone })
  const phones = getKnownPrimaryPhones()
  if (!phones.includes(phone)) {
    wx.setStorageSync("knownPrimaryPhones", [...phones, phone])
  }
}

export function getKnownPrimaryPhones() {
  const phones = wx.getStorageSync("knownPrimaryPhones")
  return Array.isArray(phones) ? phones.filter(Boolean) : []
}

export function getPrimaryAccount() {
  return wx.getStorageSync("primaryAccount") || null
}

export function getPrimaryPhone() {
  const account = getPrimaryAccount()
  return account && account.phone ? account.phone : "guest"
}

export function getTwentyMallBindingKey(phone = getPrimaryPhone()) {
  return `twentyMallBinding:${phone}`
}

export function getTwentyMallBindingOwnerKey(accountNo) {
  return `twentyMallBindingOwner:${accountNo}`
}

export function getConsumerProfileKey(phone = getPrimaryPhone()) {
  return `consumerProfile:${phone}`
}

export function getConsumerAddressesKey(phone = getPrimaryPhone()) {
  return `consumerAddresses:${phone}`
}

export function getConsumerProfile() {
  const phone = getPrimaryPhone()
  return wx.getStorageSync(getConsumerProfileKey(phone)) || null
}

export function saveConsumerProfile(profile) {
  wx.setStorageSync(getConsumerProfileKey(), profile)
}

export function fetchPrimaryProfileFromDatabase({ success, fail } = {}) {
  const phone = getPrimaryPhone()
  wx.request({
    url: `http://localhost:8080/api/twenty-mall/primary/profile?accountNo=${encodeURIComponent(phone)}&accountType=CONSUMER`,
    success: (res) => {
      if (!res.data || res.data.code !== "200" || !res.data.data) {
        if (fail) fail(getConsumerProfile())
        return
      }
      const data = res.data.data
      const profile = {
        nickname: data.displayName || "",
        phone: data.phone || data.accountNo || phone,
        avatar: normalizeDisplayAvatar(data.avatar || ""),
        bindingCount: data.bindingCount || 0
      }
      saveConsumerProfile(profile)
      if (success) success(profile)
    },
    fail: () => {
      if (fail) fail(getConsumerProfile())
    }
  })
}

export function savePrimaryProfileToDatabase(profile, { success, fail } = {}) {
  const phone = getPrimaryPhone()
  normalizeAvatarForDatabase(profile.avatar || "", {
    success: (avatar) => submitPrimaryProfile({ ...profile, avatar }, phone, success, fail),
    fail: () => {
      if (fail) fail("头像读取失败，请重新选择头像")
    }
  })
}

function submitPrimaryProfile(profile, phone, success, fail) {
  wx.request({
    url: "http://localhost:8080/api/twenty-mall/primary/profile",
    method: "POST",
    header: { "Content-Type": "application/json" },
    data: {
      accountNo: phone,
      accountType: "CONSUMER",
      displayName: profile.nickname || "",
      avatar: profile.avatar || ""
    },
    success: (res) => {
      if (!res.data || res.data.code !== "200" || !res.data.data) {
        if (fail) fail(res.data && res.data.message ? res.data.message : "资料保存失败")
        return
      }
      const data = res.data.data
      const nextProfile = {
        nickname: data.displayName || profile.nickname || "",
        phone: data.phone || data.accountNo || phone,
        avatar: normalizeDisplayAvatar(data.avatar || profile.avatar || ""),
        bindingCount: data.bindingCount || 0
      }
      saveConsumerProfile(nextProfile)
      if (success) success(nextProfile)
    },
    fail: () => {
      if (fail) fail("请先启动后端服务")
    }
  })
}

function normalizeDisplayAvatar(avatar) {
  if (!avatar || avatar.startsWith("http://tmp/") || avatar.startsWith("wxfile://")) {
    return ""
  }
  return avatar
}

function normalizeAvatarForDatabase(avatar, callbacks) {
  if (!avatar || avatar.startsWith("data:image/")) {
    callbacks.success(avatar || "")
    return
  }
  if (isLocalAvatarPath(avatar)) {
    compressAvatarFile(avatar, {
      success: (filePath) => readAvatarFile(filePath, callbacks),
      fail: () => readAvatarFile(avatar, callbacks)
    })
    return
  }
  callbacks.success("")
}

function isLocalAvatarPath(avatar) {
  return avatar.startsWith("http://tmp/")
    || avatar.startsWith("wxfile://")
    || avatar.startsWith("file://")
    || avatar.startsWith("/")
}

function compressAvatarFile(filePath, callbacks) {
  if (!wx.compressImage) {
    callbacks.fail()
    return
  }
  wx.compressImage({
    src: filePath,
    quality: 35,
    success: (res) => {
      callbacks.success(res.tempFilePath || filePath)
    },
    fail: callbacks.fail
  })
}

function readAvatarFile(filePath, callbacks) {
  const fileSystem = wx.getFileSystemManager()
  fileSystem.readFile({
    filePath,
    encoding: "base64",
    success: (res) => {
      callbacks.success(`data:image/jpeg;base64,${res.data}`)
    },
    fail: callbacks.fail
  })
}

export function getConsumerAddresses() {
  return wx.getStorageSync(getConsumerAddressesKey()) || []
}

export function saveConsumerAddresses(addresses) {
  wx.setStorageSync(getConsumerAddressesKey(), addresses)
}

export function clearConsumerAccountData(phone = getPrimaryPhone()) {
  wx.removeStorageSync(getConsumerProfileKey(phone))
  wx.removeStorageSync(getConsumerAddressesKey(phone))
  wx.removeStorageSync(`consumerLastConsultAt:${phone}`)
}

export function getTwentyMallBindings() {
  const stored = wx.getStorageSync(getTwentyMallBindingKey())
  if (Array.isArray(stored)) {
    return stored.filter((item) => item && item.platform === "万象商城")
  }
  if (stored && stored.platform === "万象商城") {
    return [stored]
  }
  return []
}

export function getTwentyMallBinding() {
  return getTwentyMallBindings()[0] || null
}

export function fetchTwentyMallBindingsFromDatabase({ success, fail } = {}) {
  const phone = getPrimaryPhone()
  wx.request({
    url: `http://localhost:8080/api/twenty-mall/primary/bindings?primaryAccountNo=${encodeURIComponent(phone)}&primaryAccountType=CONSUMER&secondaryAccountRole=CONSUMER`,
    success: (res) => {
      const rows = (res.data && res.data.data) || []
      const bindings = rows
        .filter((item) => item && item.secondaryAccountNo)
        .map((item) => ({
          accountNo: item.secondaryAccountNo,
          role: "CONSUMER",
          platform: item.platformName || "万象商城",
          boundAt: item.boundAt || ""
        }))
      wx.setStorageSync(getTwentyMallBindingKey(phone), bindings)
      if (success) success(bindings)
    },
    fail: () => {
      const cachedBindings = getTwentyMallBindings()
      if (fail) {
        fail(cachedBindings)
        return
      }
      if (success) success(cachedBindings)
    }
  })
}

export function getTwentyMallBindingOwner(accountNo) {
  return wx.getStorageSync(getTwentyMallBindingOwnerKey(accountNo)) || ""
}

export function canBindTwentyMallAccount(accountNo, phone = getPrimaryPhone()) {
  const owner = getTwentyMallBindingOwner(accountNo)
  if (owner) {
    return owner === phone
  }
  const legacyOwner = getKnownPrimaryPhones().find((knownPhone) => {
    if (knownPhone === phone) {
      return false
    }
    const bindings = wx.getStorageSync(getTwentyMallBindingKey(knownPhone))
    if (Array.isArray(bindings)) {
      return bindings.some((item) => item && item.platform === "万象商城" && item.accountNo === accountNo)
    }
    return bindings && bindings.platform === "万象商城" && bindings.accountNo === accountNo
  })
  if (legacyOwner) {
    wx.setStorageSync(getTwentyMallBindingOwnerKey(accountNo), legacyOwner)
    return false
  }
  return true
}

export function occupyTwentyMallBinding(accountNo, phone = getPrimaryPhone()) {
  wx.setStorageSync(getTwentyMallBindingOwnerKey(accountNo), phone)
}

export function saveTwentyMallBinding(binding) {
  const phone = getPrimaryPhone()
  const bindings = getTwentyMallBindings()
  const nextBinding = { ...binding, boundAt: Date.now() }
  const nextBindings = bindings.some((item) => item.accountNo === binding.accountNo)
    ? bindings.map((item) => item.accountNo === binding.accountNo ? nextBinding : item)
    : [...bindings, nextBinding]
  wx.setStorageSync(getTwentyMallBindingKey(), nextBindings)
  occupyTwentyMallBinding(binding.accountNo, phone)
  wx.removeStorageSync("twentyMallBinding")
}

export function removeTwentyMallBinding(accountNo) {
  const phone = getPrimaryPhone()
  const nextBindings = getTwentyMallBindings().filter((item) => item.accountNo !== accountNo)
  wx.setStorageSync(getTwentyMallBindingKey(), nextBindings)
  if (getTwentyMallBindingOwner(accountNo) === phone) {
    wx.removeStorageSync(getTwentyMallBindingOwnerKey(accountNo))
  }
  wx.removeStorageSync("twentyMallBinding")
}

export function clearTwentyMallBinding(phone = getPrimaryPhone()) {
  getTwentyMallBindings().forEach((binding) => {
    if (getTwentyMallBindingOwner(binding.accountNo) === phone) {
      wx.removeStorageSync(getTwentyMallBindingOwnerKey(binding.accountNo))
    }
  })
  wx.removeStorageSync(getTwentyMallBindingKey(phone))
  wx.removeStorageSync("twentyMallBinding")
}

export function getDemoToken() {
  return wx.getStorageSync('miniapp_token')
}

export function clearDemoToken() {
  wx.removeStorageSync('miniapp_token')
}

export function clearPrimaryAccountData() {
  const phone = getPrimaryPhone()
  clearTwentyMallBinding(phone)
  clearConsumerAccountData(phone)
  wx.removeStorageSync("primaryAccount")
  wx.removeStorageSync("consumerProfile")
  wx.removeStorageSync("consumerAddresses")
  wx.removeStorageSync("consumerAddress")
  wx.removeStorageSync("pendingChatOrderNo")
  clearDemoToken()
}
