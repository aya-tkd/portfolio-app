// 患者機能のAPI契約。URL・入力項目・保存方法は共通通信層ではなく、この機能が所有する。
import { request } from '../../shared/api/http.js'

// 患者編集の呼び出し元から内部IDを受け、フォーム初期表示用の患者1件を取得する。
export const loadPatient = id => request(`/api/patients/${id}`)
// 患者検索画面から、条件をURLクエリとしてGET APIへ渡す窓口。
// 戻り値は検索条件に合う患者の配列。GETは読取用途で、状態を変更する保存要求とは扱いが異なる。
export function searchPatients({ patientNumber = '', name = '' } = {}) {
  const query = new URLSearchParams()
  if (patientNumber.trim()) query.set('patient_number', patientNumber.trim())
  if (name.trim()) query.set('name', name)
  const suffix = query.toString()
  return request(`/api/patients${suffix ? `?${suffix}` : ''}`)
}
// 新規はPOST、既存はPATCHで患者を保存し、Railsの項目別エラーを呼び出し元へ返す。
export async function savePatient(id, patient) {
  // Rails発行のトークンをCookieと共に保存要求へ付け、RailsのCSRF検証を通す。
  const { token } = await request('/api/csrf')
  return request(id ? `/api/patients/${id}` : '/api/patients', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ patient }),
  })
}
