// 診療科機能のAPI契約。診療科固有のURL・入力項目・保存方法をこの機能内に閉じ込める。
import { request } from '../../../shared/api/http.js'

export const loadDepartment = id => request(`/api/departments/${id}`)

export async function saveDepartment(id, department) {
  // Rails発行のCSRFトークンをCookieと共に送り、別サイトからの保存要求を拒否できるようにする。
  const { token } = await request('/api/csrf')
  return request(id ? `/api/departments/${id}` : '/api/departments', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ department }),
  })
}
