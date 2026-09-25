// 予約画面専用のHTTP窓口。照会はGET、保存はCSRF付きPOSTで自動再送しない。
import { request } from '../../shared/api/http.js'
export const loadReservationBooking = id => request(`/api/patients/${id}/reservation_booking`)
export const loadAvailability = (id, weekStart) => request(`/api/reservation_slots/${id}/availability?week_start=${weekStart}`)
export async function saveReservations(reservation) { const { token } = await request('/api/csrf'); return request('/api/appointments/bulk', { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token }, body: JSON.stringify({ reservation }) }) }
