// ユーザーマスタ画面専用のHTTP契約。検索はGET、保存だけはCSRFトークン付きPOST/PATCHを使う。
import { request } from '../../../shared/api/http.js'
// 内部IDを指定して、診療科名・職種名を含むユーザー詳細を取得する。
export const loadUser = id => request(`/api/users/${id}`)
// 4項目の検索条件をquery stringとして送り、ユーザー一覧を取得する。
export function searchUsers({ userId = '', name = '', departmentId = '', occupationId = '' } = {}) { const q = new URLSearchParams(); if (userId) q.set('user_id', userId); if (name.trim()) q.set('name', name.trim()); if (departmentId) q.set('department_id', departmentId); if (occupationId) q.set('occupation_id', occupationId); return request(`/api/users${q.size ? `?${q}` : ''}`) }
// 新規はPOST、既存はPATCHで保存し、Railsの項目別エラーを呼び出し元へ返す。
export async function saveUser(id, user) { const { token } = await request('/api/csrf'); return request(id ? `/api/users/${id}` : '/api/users', { method: id ? 'PATCH' : 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ user }) }) }
