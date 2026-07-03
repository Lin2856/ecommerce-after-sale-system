import axios from 'axios'
import { getStoredUser, getToken } from '../utils/auth'
import { getConfirmedStaff, requireStaffIdentity } from '../utils/staffAuth'

export const api = axios.create({
  baseURL: '/api',
  timeout: 8000
})

api.interceptors.request.use((config) => {
  const token = getToken()
  if (token && token !== 'demo-token') {
    config.headers.Authorization = `Bearer ${token}`
  }
  const operationMeta = resolveProtectedOperation(config.method || 'get', config.url || '')
  if (operationMeta) {
    const staff = requireStaffIdentity()
    if (!staff) {
      return Promise.reject(new Error('请先完成客服身份确认'))
    }
    ;(config as unknown as { operationMeta?: OperationMeta }).operationMeta = operationMeta
  }
  return config
})

api.interceptors.response.use((response) => {
  const operationMeta = (response.config as unknown as { operationMeta?: OperationMeta }).operationMeta
  if (operationMeta && response.data?.code === '200') {
    writeOperationLog(operationMeta)
  }
  return response
})

export function unwrap<T>(response: { data: { data: T } }) {
  return response.data.data
}

type OperationMeta = {
  actionType: string
  actionName: string
  targetType: string
}

function resolveProtectedOperation(method: string, url: string): OperationMeta | null {
  const normalizedMethod = method.toUpperCase()
  if (normalizedMethod === 'GET' || url.includes('/merchant/operation-logs')) {
    return null
  }
  if (url.includes('/after-sales/review')) {
    return { actionType: 'AFTER_SALE_REVIEW', actionName: '审核售后申请', targetType: '售后订单' }
  }
  if (url.includes('/after-sales/refund')) {
    return { actionType: 'AFTER_SALE_REFUND', actionName: '同意退款', targetType: '售后订单' }
  }
  if (url.includes('/after-sales/disputes') && url.includes('/evidence')) {
    return { actionType: 'DISPUTE_EVIDENCE', actionName: '提交争议举证', targetType: '争议订单' }
  }
  if (url.includes('/merchant/reviews') && url.includes('/dispute')) {
    return { actionType: 'REVIEW_DISPUTE', actionName: '提出评价异议', targetType: '评价' }
  }
  if (url.includes('/merchant/knowledge/articles')) {
    return { actionType: 'KNOWLEDGE_ARTICLE', actionName: knowledgeActionName(normalizedMethod, '知识文章'), targetType: '知识库' }
  }
  if (url.includes('/merchant/knowledge/faqs')) {
    return { actionType: 'KNOWLEDGE_FAQ', actionName: knowledgeActionName(normalizedMethod, '常见问题'), targetType: '知识库' }
  }
  if (url.includes('/merchant/knowledge/rules')) {
    return { actionType: 'KNOWLEDGE_RULE', actionName: knowledgeActionName(normalizedMethod, '售后规则'), targetType: '知识库' }
  }
  return null
}

function knowledgeActionName(method: string, label: string) {
  if (method === 'POST') {
    return `新增${label}`
  }
  if (method === 'PUT' || method === 'PATCH') {
    return `修改${label}`
  }
  if (method === 'DELETE') {
    return `删除${label}`
  }
  return `维护${label}`
}

function writeOperationLog(meta: OperationMeta) {
  const staff = getConfirmedStaff()
  const user = getStoredUser<{ username?: string; phone?: string }>()
  if (!staff) {
    return
  }
  api.post('/merchant/operation-logs', {
    primaryAccount: user?.username || user?.phone || '',
    staffCode: staff.code,
    staffName: staff.name,
    actionType: meta.actionType,
    actionName: meta.actionName,
    targetType: meta.targetType,
    targetId: '当前操作对象',
    detail: `${staff.name}执行了${meta.actionName}`
  }).catch(() => undefined)
}
