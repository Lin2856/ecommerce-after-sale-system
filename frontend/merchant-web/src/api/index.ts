import { api, unwrap } from './client'

export async function loadPlatformBindings() {
  return unwrap(await api.get('/merchant/platform/shop-bindings'))
}

export async function loadSyncTasks(bindingId: number | string) {
  return unwrap(await api.get(`/merchant/platform/shop-bindings/${bindingId}/sync-tasks`))
}

export async function triggerSync(bindingId: number | string, syncType: string) {
  return unwrap(await api.post(`/merchant/platform/shop-bindings/${bindingId}/sync/${syncType}/trigger`))
}

export async function loadOrders(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/orders', { params }))
}

export async function loadTwentyMallMerchantOrders(accountNo: string) {
  return unwrap(await api.get('/twenty-mall/merchant/orders', { params: { accountNo } }))
}

export async function loadAfterSales(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/after-sales', { params }))
}

export async function loadTwentyMallMerchantAfterSales(accountNo: string) {
  return unwrap(await api.get('/twenty-mall/merchant/after-sales', { params: { accountNo } }))
}

function selfBuiltApiPrefix(platformCode = 'TWENTY_MALL') {
  return platformCode === 'YUEGOU_MARKET' ? '/yuegou-market' : '/twenty-mall'
}

export async function loadSelfBuiltMerchantAfterSales(accountNo: string, platformCode = 'TWENTY_MALL') {
  return unwrap(await api.get(`${selfBuiltApiPrefix(platformCode)}/merchant/after-sales`, { params: { accountNo } }))
}

export async function reviewTwentyMallAfterSale(afterSaleId: number, result: 'APPROVE' | 'REJECT', reason = '') {
  return unwrap(await api.post('/twenty-mall/merchant/after-sales/review', { afterSaleId, result, reason }))
}

export async function reviewSelfBuiltAfterSale(afterSaleId: number, result: 'APPROVE' | 'REJECT', reason = '', platformCode = 'TWENTY_MALL') {
  return unwrap(await api.post(`${selfBuiltApiPrefix(platformCode)}/merchant/after-sales/review`, { afterSaleId, result, reason }))
}

export async function refundTwentyMallAfterSale(afterSaleId: number) {
  return unwrap(await api.post('/twenty-mall/merchant/after-sales/refund', { afterSaleId }))
}

export async function refundSelfBuiltAfterSale(afterSaleId: number, platformCode = 'TWENTY_MALL') {
  return unwrap(await api.post(`${selfBuiltApiPrefix(platformCode)}/merchant/after-sales/refund`, { afterSaleId }))
}

export async function loadTwentyMallMerchantAfterSaleDisputes(accountNo: string) {
  return unwrap(await api.get('/twenty-mall/merchant/after-sales/disputes', { params: { accountNo } }))
}

export async function loadSelfBuiltMerchantAfterSaleDisputes(accountNo: string, platformCode = 'TWENTY_MALL') {
  return unwrap(await api.get(`${selfBuiltApiPrefix(platformCode)}/merchant/after-sales/disputes`, { params: { accountNo } }))
}

export async function submitTwentyMallMerchantDisputeEvidence(disputeId: number, evidenceText: string, evidenceImages: string[] = []) {
  return unwrap(await api.post(`/twenty-mall/merchant/after-sales/disputes/${disputeId}/evidence`, {
    evidenceText,
    evidenceImages
  }))
}

export async function submitSelfBuiltMerchantDisputeEvidence(disputeId: number, evidenceText: string, evidenceImages: string[] = [], platformCode = 'TWENTY_MALL') {
  return unwrap(await api.post(`${selfBuiltApiPrefix(platformCode)}/merchant/after-sales/disputes/${disputeId}/evidence`, {
    evidenceText,
    evidenceImages
  }))
}

export async function loadConversations() {
  return unwrap(await api.get('/merchant/conversations'))
}

export async function loadDemoChatConversations(merchantAccounts: string[] = []) {
  return unwrap(await api.get('/demo-chat/conversations', { params: { merchantAccounts } }))
}

export async function loadTickets(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/tickets', { params }))
}

export async function loadReviews(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/reviews', { params }))
}

export function recordAiCallLog(payload: {
  merchantId?: number | null
  businessType: string
  businessId?: number | null
  taskType: string
  requestText?: string
  responseText?: string
  success?: boolean
  errorMessage?: string
  latencyMs?: number
}) {
  return api.post('/merchant/ai/call-log', payload).catch(() => undefined)
}

export async function loadTwentyMallMerchantReviews(accountNo: string) {
  return unwrap(await api.get('/twenty-mall/merchant/reviews', { params: { accountNo } }))
}

export async function loadSelfBuiltMerchantReviews(accountNo: string, platformCode = 'TWENTY_MALL') {
  return unwrap(await api.get(`${selfBuiltApiPrefix(platformCode)}/merchant/reviews`, { params: { accountNo } }))
}

export async function loadTwentyMallMerchantNotifications(accountNo: string) {
  return unwrap(await api.get('/twenty-mall/merchant/notifications', { params: { accountNo } }))
}

export async function submitTwentyMallReviewDispute(reviewId: number, accountNo: string, reason: string) {
  return unwrap(await api.post(`/twenty-mall/merchant/reviews/${reviewId}/dispute`, { accountNo, reason }))
}

export async function submitSelfBuiltReviewDispute(reviewId: number, accountNo: string, reason: string, platformCode = 'TWENTY_MALL') {
  return unwrap(await api.post(`${selfBuiltApiPrefix(platformCode)}/merchant/reviews/${reviewId}/dispute`, { accountNo, reason }))
}

export async function loadArticles(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/knowledge/articles', { params }))
}

export async function loadFaqs(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/knowledge/faqs', { params }))
}

export async function loadRules(params: Record<string, unknown> = {}) {
  return unwrap(await api.get('/merchant/knowledge/rules', { params }))
}

export async function loadOperationLogs(primaryAccount = '') {
  return unwrap(await api.get('/merchant/operation-logs', { params: { primaryAccount } }))
}

export async function createOperationLog(payload: Record<string, unknown>) {
  return unwrap(await api.post('/merchant/operation-logs', payload))
}

export async function merchantWechatLogin(accountNo: string) {
  return unwrap(await api.post('/twenty-mall/merchant/wechat-login', { accountNo }))
}

export async function sendMerchantVerificationCode(phone: string) {
  return unwrap(await api.post('/twenty-mall/merchant/verification-code/send', { phone }))
}

export async function merchantPhoneCodeLogin(phone: string, code: string) {
  return unwrap(await api.post('/twenty-mall/merchant/phone-login', { phone, code }))
}

export async function loadPrimaryBanStatus(accountNo: string, accountType: 'CONSUMER' | 'MERCHANT') {
  return unwrap(await api.get('/twenty-mall/primary/ban-status', { params: { accountNo, accountType } }))
}

export async function loadMerchantWechatQrUrl(redirectUri: string) {
  const response = await api.get('/twenty-mall/merchant/wechat/qr-url', { params: { redirectUri } })
  if (response.data?.code !== '200' || !response.data?.data) {
    throw new Error(response.data?.message || '微信扫码登录暂不可用')
  }
  return response.data.data
}

export async function merchantWechatCallbackLogin(code: string, state: string) {
  const response = await api.post('/twenty-mall/merchant/wechat-login', { code, state })
  if (response.data?.code !== '200' || !response.data?.data) {
    throw new Error(response.data?.message || '微信扫码登录失败')
  }
  return response.data.data
}
