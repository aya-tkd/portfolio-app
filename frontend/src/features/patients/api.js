// 患者機能のAPI契約。URL・入力項目・保存方法は共通通信層ではなく、この機能が所有する。
import { request } from '../../shared/api/http.js'

export const loadPatient = id => request(`/api/patients/${id}`)
export async function savePatient(id, patient) {
  // 保存前にRails発行のCSRFトークンを取得し、Cookieと共に送信して正当な操作か検証させる。
  const { token } = await request('/api/csrf')
  return request(id ? `/api/patients/${id}` : '/api/patients', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ patient }),
  })
}
