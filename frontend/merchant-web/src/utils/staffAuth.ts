import { getStoredUser } from './auth'

export type MerchantStaffIdentity = {
  code: string
  name: string
}

export const MERCHANT_STAFFS: MerchantStaffIdentity[] = [
  { code: 'A', name: '客服A' },
  { code: 'B', name: '客服B' },
  { code: 'C', name: '客服C' },
  { code: 'D', name: '客服D' }
]

const STAFF_KEYS: Record<string, string> = {
  A: 'AAAA',
  B: 'BBBB',
  C: 'CCCC',
  D: 'DDDD'
}

function currentAccountKey() {
  const user = getStoredUser<{ username?: string; phone?: string; userId?: number }>()
  return user?.username || user?.phone || user?.userId || 'anonymous'
}

export function staffSessionKey() {
  return `merchant_staff_identity:${currentAccountKey()}`
}

export function getConfirmedStaff() {
  const raw = sessionStorage.getItem(staffSessionKey())
  if (!raw) {
    return null
  }
  try {
    return JSON.parse(raw) as MerchantStaffIdentity
  } catch {
    return null
  }
}

export function confirmStaffIdentity(code: string, secret: string) {
  const staff = MERCHANT_STAFFS.find((item) => item.code === code)
  if (!staff || STAFF_KEYS[code] !== secret.trim()) {
    return null
  }
  sessionStorage.setItem(staffSessionKey(), JSON.stringify(staff))
  return staff
}

export function clearStaffIdentity() {
  sessionStorage.removeItem(staffSessionKey())
}

export function requireStaffIdentity() {
  const staff = getConfirmedStaff()
  if (staff) {
    return staff
  }
  window.dispatchEvent(new CustomEvent('merchant-staff-required'))
  return null
}
