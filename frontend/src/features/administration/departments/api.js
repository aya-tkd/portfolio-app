// 診療科機能のAPI契約。診療科固有のURL・入力項目・保存方法をこの機能内に閉じ込める。
import { request } from '../../../shared/api/http.js'

// 内部IDを指定して、編集フォームに表示する診療科1件を取得する。
export const loadDepartment = id => request(`/api/departments/${id}`)

// 検索条件をquery stringとして送り、一致する診療科一覧を取得する。
export function searchDepartments({ keyword = '', active = '' } = {}) {
  const query = new URLSearchParams()
  if (keyword.trim()) query.set('keyword', keyword.trim())
  if (active !== '') query.set('active', active)
  return request(`/api/departments${query.size ? `?${query}` : ''}`)
}

// 新規はPOST、既存はPATCHで保存し、Railsの項目別エラーを呼び出し元へ返す。
export async function saveDepartment(id, department) {
  // Rails発行のCSRFトークンをCookieと共に送り、別サイトからの保存要求を拒否できるようにする。
  const { token } = await request('/api/csrf')
  return request(id ? `/api/departments/${id}` : '/api/departments', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ department }),
  })
}
