// 外来画面の通信契約。読取結果は一覧DTO、更新結果は更新した受付のDTOを返す。
// 進捗の確定はRailsで行い、自動再送による二重処理を避ける。
import { request } from '../../shared/api/http.js'

export function loadOutpatients({ date, departmentId = '', statuses } = {}) {
  const query = new URLSearchParams()
  if (date) query.set('date', date)
  if (departmentId) query.set('department_id', departmentId)
  // 未選択は呼出元で0件にする。空配列を「全選択」へ変換しない。
  statuses?.forEach(status => query.append('statuses[]', status))
  return request(`/api/outpatients?${query}`)
}

export async function advanceOutpatient(row, action, equipmentId = null) {
  const { token } = await request('/api/csrf')
  return request(`/api/outpatients/${row.reception_id}`, {
    method: 'PATCH', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ operation: { action, version: row.version, equipment_id: equipmentId } }),
  })
}
