// ユーザーマスタ画面専用のHTTP契約。検索はGET、保存だけはCSRFトークン付きPOST/PATCHを使う。
import { request } from '../../../shared/api/http.js'
export const loadUser = id => request(`/api/users/${id}`)
export function searchUsers({ userId = '', name = '', departmentId = '', occupationId = '' } = {}) { const q = new URLSearchParams(); if (userId) q.set('user_id', userId); if (name.trim()) q.set('name', name.trim()); if (departmentId) q.set('department_id', departmentId); if (occupationId) q.set('occupation_id', occupationId); return request(`/api/users${q.size ? `?${q}` : ''}`) }
export async function saveUser(id, user) { const { token } = await request('/api/csrf'); return request(id ? `/api/users/${id}` : '/api/users', { method: id ? 'PATCH' : 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ user }) }) }
