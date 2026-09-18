// 受付画面専用のAPI窓口。候補取得はGET、登録はCSRFトークン付きPOSTとしてRails APIへ送る。
import { request } from '../../shared/api/http.js'

export const loadReceptionCandidates = patientId => request(`/api/patients/${patientId}/reception_candidates`)

export async function registerReceptions(reception) {
  const { token } = await request('/api/csrf')
  return request('/api/receptions', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ reception }),
  })
}
