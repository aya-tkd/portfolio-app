// 職種機能のAPI契約。職種固有のURL・保存項目を機能配下に閉じ込める。
import { request } from '../../../shared/api/http.js'

export const loadOccupation = id => request(`/api/occupations/${id}`)

export async function saveOccupation(id, occupation) {
  const { token } = await request('/api/csrf')
  return request(id ? `/api/occupations/${id}` : '/api/occupations', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ occupation }),
  })
}
