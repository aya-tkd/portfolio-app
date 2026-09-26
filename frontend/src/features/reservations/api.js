// 予約画面専用のHTTP窓口。照会はGET、保存はCSRF付きPOSTで自動再送しない。
import { request } from '../../shared/api/http.js'
// 予約画面の初期表示に使う、患者・予約枠・選択肢・登録済み予約を取得する。
export const loadReservationBooking = id => request(`/api/patients/${id}/reservation_booking`)
// 選択枠の1週間分について、予約可能時刻と残数を取得する。
export const loadAvailability = (id, weekStart) => request(`/api/reservation_slots/${id}/availability?week_start=${weekStart}`)
// 画面内で確定した予約一覧をまとめて保存し、受付作成前の予約レコードを返す。
export async function saveReservations(reservation) { const { token } = await request('/api/csrf'); return request('/api/appointments/bulk', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ reservation }) }) }
