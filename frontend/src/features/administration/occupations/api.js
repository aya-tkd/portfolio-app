// 職種機能のAPI契約。職種固有のURL・保存項目を機能配下に閉じ込める。
import { request } from '../../../shared/api/http.js'

// 内部IDを指定して、編集フォームに表示する職種1件を取得する。
export const loadOccupation = id => request(`/api/occupations/${id}`)

// 検索条件をquery stringとして送り、一致する職種一覧を取得する。
export function searchOccupations({ keyword = '', active = '' } = {}) {
  const query = new URLSearchParams()
  if (keyword.trim()) query.set('keyword', keyword.trim())
  if (active !== '') query.set('active', active)
  return request(`/api/occupations${query.size ? `?${query}` : ''}`)
}

// 新規はPOST、既存はPATCHで保存し、Railsの項目別エラーを呼び出し元へ返す。
export async function saveOccupation(id, occupation) {
  const { token } = await request('/api/csrf')
  return request(id ? `/api/occupations/${id}` : '/api/occupations', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ occupation }),
  })
}
