// 予約枠マスタ画面専用のHTTP契約。検索・選択肢取得はGET、登録更新はCSRFトークン付きPOST/PATCHに限定する。
import { request } from '../../../shared/api/http.js'

// 内部IDを指定し、編集フォーム用の予約枠1件を取得する。
export const loadReservationSlot = id => request(`/api/reservation_slots/${id}`)
// 編集フォームの診療科・医師selectに使う有効な選択肢を取得する。
export const loadReservationSlotOptions = () => request('/api/reservation_slots/options')

// 検索・絞り込み条件とページを送り、予約枠一覧を取得する。
export function searchReservationSlots({ keyword = '', slotGroup = '', defaultDepartmentId = '', active = '', page = 1, perPage = 50 } = {}) {
  const query = new URLSearchParams({ page: String(page), per_page: String(perPage) })
  if (keyword.trim()) query.set('keyword', keyword.trim())
  if (slotGroup) query.set('slot_group', slotGroup)
  if (defaultDepartmentId) query.set('default_department_id', defaultDepartmentId)
  if (active !== '') query.set('active', String(active))
  return request(`/api/reservation_slots?${query}`)
}

// 新規はPOST、既存はPATCHで保存し、Railsの入力エラーを返す。
export async function saveReservationSlot(id, reservationSlot) {
  const { token } = await request('/api/csrf')
  return request(id ? `/api/reservation_slots/${id}` : '/api/reservation_slots', {
    method: id ? 'PATCH' : 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
    body: JSON.stringify({ reservation_slot: reservationSlot }),
  })
}
