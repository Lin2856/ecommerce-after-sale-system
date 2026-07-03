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

const LOCAL_PLATFORM_CONFIGS = {
  TWENTY_MALL: {
    name: "万象商城",
    apiPrefix: "/api/twenty-mall",
    bindingKeyPrefix: "twentyMallBinding",
    ownerKeyPrefix: "twentyMallBindingOwner"
  },
  YUEGOU_MARKET: {
    name: "悦购集市",
    apiPrefix: "/api/yuegou-market",
    bindingKeyPrefix: "yuegouMarketBinding",
    ownerKeyPrefix: "yuegouMarketBindingOwner"
  }
}

export function getLocalPlatformConfig(platformCode = "TWENTY_MALL") {
  return LOCAL_PLATFORM_CONFIGS[platformCode] || LOCAL_PLATFORM_CONFIGS.TWENTY_MALL
}

export function getLocalPlatformBindingKey(platformCode = "TWENTY_MALL", phone = getPrimaryPhone()) {
  return `${getLocalPlatformConfig(platformCode).bindingKeyPrefix}:${phone}`
}

export function getLocalPlatformBindingOwnerKey(platformCode = "TWENTY_MALL", accountNo) {
  return `${getLocalPlatformConfig(platformCode).ownerKeyPrefix}:${accountNo}`
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
        phone: displayablePhone(data.phone) || displayablePhone(data.accountNo || phone),
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
        phone: displayablePhone(data.phone) || displayablePhone(data.accountNo || phone),
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

function isWechatPrimaryAccount(accountNo) {
  return typeof accountNo === "string" && accountNo.startsWith("wx_")
}

function displayablePhone(phone) {
  if (!phone || phone === "guest" || isWechatPrimaryAccount(phone)) {
    return ""
  }
  return phone
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
  return getLocalPlatformBindings("TWENTY_MALL")
}

export function getLocalPlatformBindings(platformCode = "TWENTY_MALL") {
  const config = getLocalPlatformConfig(platformCode)
  const stored = wx.getStorageSync(getLocalPlatformBindingKey(platformCode))
  if (Array.isArray(stored)) {
    return stored.filter((item) => item && item.platform === config.name)
  }
  if (stored && stored.platform === config.name) {
    return [stored]
  }
  return []
}

export function getTwentyMallBinding() {
  return getTwentyMallBindings()[0] || null
}

export function fetchTwentyMallBindingsFromDatabase({ success, fail } = {}) {
  fetchLocalPlatformBindingsFromDatabase("TWENTY_MALL", { success, fail })
}

export function fetchLocalPlatformBindingsFromDatabase(platformCode = "TWENTY_MALL", { success, fail } = {}) {
  const phone = getPrimaryPhone()
  const config = getLocalPlatformConfig(platformCode)
  wx.request({
    url: `http://localhost:8080${config.apiPrefix}/primary/bindings?primaryAccountNo=${encodeURIComponent(phone)}&primaryAccountType=CONSUMER&secondaryAccountRole=CONSUMER`,
    success: (res) => {
      const rows = (res.data && res.data.data) || []
      const bindings = rows
        .filter((item) => item && item.secondaryAccountNo && (item.platformCode ? item.platformCode === platformCode : (item.platformName || config.name) === config.name))
        .map((item) => ({
          accountNo: item.secondaryAccountNo,
          role: "CONSUMER",
          platform: item.platformName || config.name,
          boundAt: item.boundAt || ""
        }))
      wx.setStorageSync(getLocalPlatformBindingKey(platformCode, phone), bindings)
      if (success) success(bindings)
    },
    fail: () => {
      const cachedBindings = getLocalPlatformBindings(platformCode)
      if (fail) {
        fail(cachedBindings)
        return
      }
      if (success) success(cachedBindings)
    }
  })
}

export function getTwentyMallBindingOwner(accountNo) {
  return getLocalPlatformBindingOwner("TWENTY_MALL", accountNo)
}

export function getLocalPlatformBindingOwner(platformCode = "TWENTY_MALL", accountNo) {
  return wx.getStorageSync(getLocalPlatformBindingOwnerKey(platformCode, accountNo)) || ""
}

export function canBindTwentyMallAccount(accountNo, phone = getPrimaryPhone()) {
  return canBindLocalPlatformAccount("TWENTY_MALL", accountNo, phone)
}

export function canBindLocalPlatformAccount(platformCode = "TWENTY_MALL", accountNo, phone = getPrimaryPhone()) {
  const config = getLocalPlatformConfig(platformCode)
  const owner = getLocalPlatformBindingOwner(platformCode, accountNo)
  if (owner) {
    return owner === phone
  }
  const legacyOwner = getKnownPrimaryPhones().find((knownPhone) => {
    if (knownPhone === phone) {
      return false
    }
    const bindings = wx.getStorageSync(getLocalPlatformBindingKey(platformCode, knownPhone))
    if (Array.isArray(bindings)) {
      return bindings.some((item) => item && item.platform === config.name && item.accountNo === accountNo)
    }
    return bindings && bindings.platform === config.name && bindings.accountNo === accountNo
  })
  if (legacyOwner) {
    wx.setStorageSync(getLocalPlatformBindingOwnerKey(platformCode, accountNo), legacyOwner)
    return false
  }
  return true
}

export function occupyTwentyMallBinding(accountNo, phone = getPrimaryPhone()) {
  occupyLocalPlatformBinding("TWENTY_MALL", accountNo, phone)
}

export function occupyLocalPlatformBinding(platformCode = "TWENTY_MALL", accountNo, phone = getPrimaryPhone()) {
  wx.setStorageSync(getLocalPlatformBindingOwnerKey(platformCode, accountNo), phone)
}

export function saveTwentyMallBinding(binding) {
  saveLocalPlatformBinding("TWENTY_MALL", binding)
}

export function saveLocalPlatformBinding(platformCode = "TWENTY_MALL", binding) {
  const phone = getPrimaryPhone()
  const config = getLocalPlatformConfig(platformCode)
  const bindings = getLocalPlatformBindings(platformCode)
  const normalizedBinding = { ...binding, platform: binding.platform || config.name }
  const nextBinding = { ...normalizedBinding, boundAt: Date.now() }
  const nextBindings = bindings.some((item) => item.accountNo === binding.accountNo)
    ? bindings.map((item) => item.accountNo === binding.accountNo ? nextBinding : item)
    : [...bindings, nextBinding]
  wx.setStorageSync(getLocalPlatformBindingKey(platformCode), nextBindings)
  occupyLocalPlatformBinding(platformCode, binding.accountNo, phone)
  wx.removeStorageSync(getLocalPlatformConfig(platformCode).bindingKeyPrefix)
}

export function removeTwentyMallBinding(accountNo) {
  removeLocalPlatformBinding("TWENTY_MALL", accountNo)
}

export function removeLocalPlatformBinding(platformCode = "TWENTY_MALL", accountNo) {
  const phone = getPrimaryPhone()
  const nextBindings = getLocalPlatformBindings(platformCode).filter((item) => item.accountNo !== accountNo)
  wx.setStorageSync(getLocalPlatformBindingKey(platformCode), nextBindings)
  if (getLocalPlatformBindingOwner(platformCode, accountNo) === phone) {
    wx.removeStorageSync(getLocalPlatformBindingOwnerKey(platformCode, accountNo))
  }
  wx.removeStorageSync(getLocalPlatformConfig(platformCode).bindingKeyPrefix)
}

export function clearTwentyMallBinding(phone = getPrimaryPhone()) {
  clearLocalPlatformBinding("TWENTY_MALL", phone)
}

export function clearLocalPlatformBinding(platformCode = "TWENTY_MALL", phone = getPrimaryPhone()) {
  getLocalPlatformBindings(platformCode).forEach((binding) => {
    if (getLocalPlatformBindingOwner(platformCode, binding.accountNo) === phone) {
      wx.removeStorageSync(getLocalPlatformBindingOwnerKey(platformCode, binding.accountNo))
    }
  })
  wx.removeStorageSync(getLocalPlatformBindingKey(platformCode, phone))
  wx.removeStorageSync(getLocalPlatformConfig(platformCode).bindingKeyPrefix)
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
  clearLocalPlatformBinding("YUEGOU_MARKET", phone)
  clearConsumerAccountData(phone)
  wx.removeStorageSync("primaryAccount")
  wx.removeStorageSync("consumerProfile")
  wx.removeStorageSync("consumerAddresses")
  wx.removeStorageSync("consumerAddress")
  wx.removeStorageSync("pendingChatOrderNo")
  clearDemoToken()
}
