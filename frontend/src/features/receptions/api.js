// 受付画面専用のAPI窓口。候補取得はGET、登録はCSRFトークン付きPOSTとしてRails APIへ送る。
import { request } from '../../shared/api/http.js'

// 患者の当日予約と受付候補となる診療科・医師を取得する。
export const loadReceptionCandidates = patientId => request(`/api/patients/${patientId}/reception_candidates`)

// 選択した複数対象を一括受付し、作成された受付一覧を返す。
export async function registerReceptions(reception) {
  const { token } = await request('/api/csrf')
  return request('/api/receptions', {
    method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ reception }),
  })
}
