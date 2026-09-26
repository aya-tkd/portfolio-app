<script setup>
// 外来一覧の予約導線と直接URLから利用する患者予約画面。
// 空き照会は週・枠ごと、確定内容は画面内で保持し、登録確認後だけAPIへ一括送信する。
import { computed, nextTick, onMounted, onBeforeUnmount, ref, watch } from 'vue'
import PatientBanner from '../../../shared/components/PatientBanner.vue'
import { loadAvailability, loadReservationBooking, saveReservations } from '../api.js'

const props = defineProps({ patientId: { type: [String, Number], default: null } })
const emit = defineEmits(['cancelled', 'completed'])
const patientId = props.patientId || new URLSearchParams(location.search).get('patient_id')
const data = ref(null), selected = ref([]), active = ref(null), cart = ref([])
const week = ref(monday(dateKey(new Date()))), times = ref([])
const loading = ref(false), saving = ref(false), message = ref(''), failed = ref(false)
const draft = ref(null), dialogError = ref(''), modal = ref(null), modalKind = ref('')
let sequence = 0

// 週カレンダーの日付計算。ブラウザの実行環境に左右されないよう日本時間を明示する。
function dateKey(date) {
  return new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Tokyo' }).format(date)
}
function addDays(value, count) {
  const date = new Date(`${value}T12:00:00+09:00`)
  date.setTime(date.getTime() + count * 86400000)
  return dateKey(date)
}
function monday(value) {
  const day = new Date(`${value}T12:00:00+09:00`).getUTCDay()
  return addDays(value, -((day + 6) % 7))
}
const timeLabel = value => new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', hour: '2-digit', minute: '2-digit', hour12: false }).format(new Date(value))
const dateLabel = value => new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', month: 'numeric', day: 'numeric', weekday: 'short' }).format(new Date(value))
const stamp = item => `${dateLabel(item.scheduled_at)} ${timeLabel(item.scheduled_at)}`
const groups = computed(() => ['consultation', 'equipment'].map(kind => ({ kind, name: kind === 'consultation' ? '診察' : '設備', slots: (data.value?.reservation_slots || []).filter(slot => slot.slot_group === kind) })))
const chosenSlots = computed(() => selected.value.map(id => data.value?.reservation_slots.find(slot => slot.id === id)).filter(Boolean))
const current = computed(() => chosenSlots.value.find(slot => slot.id === active.value) || chosenSlots.value[0])
const days = computed(() => Array.from({ length: 7 }, (_, index) => addDays(week.value, index)))
const clockRows = computed(() => [...new Set(times.value.map(cell => timeLabel(cell.scheduled_at)))].sort())
const cells = computed(() => new Map(times.value.map(cell => [`${dateKey(new Date(cell.scheduled_at))}/${timeLabel(cell.scheduled_at)}`, cell])))
const cellAt = (day, clock) => cells.value.get(`${day}/${clock}`)
const doctors = computed(() => (data.value?.doctor_users || []).filter(doctor => doctor.department_id == null || doctor.department_id === draft.value?.department_id))
const parents = computed(() => cart.value.filter(item => item.slot.slot_group === 'consultation' && dateKey(new Date(item.scheduled_at)) === dateKey(new Date(draft.value.scheduled_at))))
const departmentName = id => data.value.departments.find(item => item.id === id)?.name || '—'
const doctorName = id => data.value.doctor_users.find(item => item.id === id)?.name || '医師未定'
const parentFor = item => cart.value.find(parent => parent.key === item.parent_entry_key)
const attributes = item => parentFor(item) || item
const selectedTime = cell => cart.value.some(item => item.slot.id === current.value?.id && item.scheduled_at === cell.scheduled_at)

// current枠または週が変わるとwatchから呼ばれ、その条件の空き時間を再取得する。
// 古い週の応答で新しい週を上書きしない。失敗時も前週の空きを選べないよう先にクリアする。
async function reload() {
  const requestSequence = ++sequence
  times.value = []
  if (!current.value) { loading.value = false; return }
  loading.value = true
  try {
    const response = await loadAvailability(current.value.id, week.value)
    if (requestSequence === sequence) times.value = response.times
  } catch (error) {
    if (requestSequence === sequence) { message.value = error.message || '空き時間を取得できませんでした。'; failed.value = true }
  } finally { if (requestSequence === sequence) loading.value = false }
}
// Vueのwatchで選択枠・週の変更を監視し、表示カレンダーを同期する。
watch([() => current.value?.id, week], reload)
function changeWeek(event) { if (event.target.value) week.value = monday(event.target.value) }
function toggle(id) {
  selected.value = selected.value.includes(id) ? selected.value.filter(value => value !== id) : [...selected.value, id]
  if (!selected.value.includes(active.value)) active.value = selected.value[0]
}
async function showModal(kind) {
  modalKind.value = kind
  dialogError.value = ''
  await nextTick()
  modal.value.showModal()
}
function dismiss() { if (saving.value) return; modal.value.close(); modalKind.value = ''; draft.value = null }
// 空きセルから仮予約を作り、診療科・医師・設備の紐付けを行うdialogを開く。
function openTime(cell) {
  if (selectedTime(cell)) return
  const slot = current.value
  draft.value = { key: crypto.randomUUID(), slot, scheduled_at: cell.scheduled_at, department_id: slot.default_department_id || '', doctor_user_id: slot.default_doctor_user_id || '', parent_entry_key: '' }
  resetDoctor()
  showModal('entry')
}
// 予約内容ペインから登録前の設備紐付けを編集する。
function editLink(item) { draft.value = { ...item }; showModal('entry') }
function resetDoctor() { if (!doctors.value.some(doctor => doctor.id === draft.value.doctor_user_id)) draft.value.doctor_user_id = '' }
function inheritParent() {
  const parent = parentFor(draft.value)
  if (parent) { draft.value.department_id = parent.department_id; draft.value.doctor_user_id = parent.doctor_user_id }
}
// dialogで確定した内容を画面内カートへ反映する。DB登録はsaveまで行わない。
function confirmEntry() {
  inheritParent()
  if (!draft.value.department_id) { dialogError.value = '診療科を選択してください。'; return }
  const index = cart.value.findIndex(item => item.key === draft.value.key)
  if (index < 0) cart.value.push({ ...draft.value })
  else cart.value[index] = { ...draft.value }
  dismiss()
}
// カートから1件外す。診察を外す場合も子設備は残して親との紐付けだけ解除する。
function remove(item) {
  // 親を除去しても設備予約は残し、引き継いだ診療科・医師を保持して紐付けだけ解除する。
  cart.value = cart.value.filter(value => value.key !== item.key).map(value => value.parent_entry_key === item.key ? { ...value, department_id: item.department_id, doctor_user_id: item.doctor_user_id, parent_entry_key: '' } : value)
}
function leave() {
  if (props.patientId) emit('cancelled')
  else window.location.assign('/outpatients')
}
// 登録中は閉じず、未登録内容がある場合は破棄確認を挟む。
function close() { if (saving.value) return; if (cart.value.length) showModal('discard'); else leave() }
function beforeUnload(event) { if (cart.value.length) { event.preventDefault(); event.returnValue = '' } }
// カート内容を一括POSTし、DBの最終検証後に登録済み予約を再取得する。
async function save() {
  if (saving.value || !cart.value.length) return
  saving.value = true
  dialogError.value = ''
  try {
    await saveReservations({ patient_id: Number(patientId), entries: cart.value.map(item => ({ entry_key: item.key, reservation_slot_id: item.slot.id, scheduled_at: item.scheduled_at, department_id: attributes(item).department_id, doctor_user_id: attributes(item).doctor_user_id || null, parent_entry_key: item.parent_entry_key || null })) })
  } catch (error) {
    dialogError.value = error.message || '登録できませんでした。予約内容を確認してください。'
    saving.value = false
    await reload()
    return
  }
  // 保存成功後の再読込失敗を登録失敗と混同せず、二重登録を避ける。
  cart.value = []
  saving.value = false
  dismiss()
  message.value = '予約を登録しました。'
  failed.value = false
  try { data.value = await loadReservationBooking(patientId); await reload() }
  catch { message.value = '予約は登録済みです。登録済み予約の再表示に失敗しました。'; failed.value = true }
}
onMounted(async () => {
  // 初回表示時に患者・枠等を取得し、ブラウザ遷移時は未登録内容を保護する。
  window.addEventListener('beforeunload', beforeUnload)
  try { data.value = await loadReservationBooking(patientId) }
  catch (error) { message.value = error.message || '患者を読み込めませんでした。'; failed.value = true }
})
onBeforeUnmount(() => { sequence++; window.removeEventListener('beforeunload', beforeUnload) })
</script>

<template>
  <main class="reservation-workspace">
    <!-- 患者の特定情報と通信・保存メッセージ。 -->
    <PatientBanner v-if="data" :patient="data.patient" />
    <p v-if="message" class="reservation-message" :class="{ error: failed }" role="status">{{ message }}</p>
    <p v-if="!data && !message" role="status">読み込み中です。</p>
    <section v-if="data" class="reservation-layout">
      <!-- 診察／設備に分類した枠を複数選択する領域。 -->
      <section class="reservation-panel" aria-label="予約枠">
        <header class="panel-head"><h1>予約枠</h1><span>複数選択可</span></header>
        <div class="panel-scroll slot-tree">
          <details v-for="group in groups" :key="group.kind" open>
            <summary>{{ group.name }}</summary>
            <label v-for="slot in group.slots" :key="slot.id" class="slot-choice">
              <input type="checkbox" :checked="selected.includes(slot.id)" @change="toggle(slot.id)"><span>{{ slot.name }}</span>
            </label>
            <p v-if="!group.slots.length" class="empty">予約枠がありません。</p>
          </details>
        </div>
      </section>
      <!-- 共通の週操作と、選択枠の空き時間カレンダー。 -->
      <section class="reservation-panel" aria-label="空き時間">
        <header class="panel-head"><h1>空き時間</h1><span>{{ week.replaceAll('-', '/') }}〜{{ days[6].slice(5).replace('-', '/') }}</span></header>
        <div class="week-controls">
          <label>表示週<input type="date" class="form-control" :value="week" @change="changeWeek"></label>
          <button type="button" class="btn btn-secondary" @click="week = addDays(week, -7)">前週</button>
          <button type="button" class="btn btn-secondary" @click="week = addDays(week, 7)">次週</button>
        </div>
        <div v-if="chosenSlots.length" class="slot-tabs" aria-label="表示する予約枠">
          <button v-for="slot in chosenSlots" :key="slot.id" type="button" :class="{ active: slot.id === current?.id }" :aria-pressed="slot.id === current?.id" :title="slot.name" @click="active = slot.id">{{ slot.name }}</button>
        </div>
        <div class="panel-scroll calendar-scroll" :aria-busy="loading">
          <p v-if="!current" class="empty">予約枠を選択してください。</p>
          <p v-else-if="loading" class="empty" role="status">空き時間を読み込み中です。</p>
          <template v-else>
            <table class="week-calendar" aria-label="週間の空き時間">
              <thead><tr><th scope="col">時刻</th><th v-for="day in days" :key="day" scope="col"><span>{{ Number(day.slice(5,7)) }}/{{ Number(day.slice(8)) }}</span><br>{{ ['日','月','火','水','木','金','土'][new Date(`${day}T12:00:00+09:00`).getUTCDay()] }}</th></tr></thead>
              <tbody><tr v-for="clock in clockRows" :key="clock"><th scope="row">{{ clock }}</th><td v-for="day in days" :key="day">
                <button v-if="cellAt(day, clock)" type="button" class="time-cell" :class="{ selected: selectedTime(cellAt(day,clock)) }" :disabled="!cellAt(day,clock).remaining || selectedTime(cellAt(day,clock))" :aria-label="`${day} ${clock} ${selectedTime(cellAt(day,clock)) ? '選択済み' : '残' + cellAt(day,clock).remaining}`" @click="openTime(cellAt(day,clock))">{{ selectedTime(cellAt(day,clock)) ? '選択済' : cellAt(day,clock).remaining ? `残${cellAt(day,clock).remaining}` : '満員' }}</button>
                <span v-else class="unavailable">—</span>
              </td></tr></tbody>
            </table>
            <p v-if="!clockRows.length" class="empty">この週に予約可能な時間枠はありません。</p>
          </template>
        </div>
      </section>
      <div class="reservation-right">
        <!-- 時間選択後に画面内で確定した内容と設備の紐付けを編集する。 -->
        <section class="reservation-panel" aria-label="予約内容">
          <header class="panel-head"><h1>予約内容</h1><span>{{ cart.length }}件</span></header>
          <div class="panel-scroll booking-list">
            <p v-if="!cart.length" class="empty">予約内容はありません。</p>
            <article v-for="item in cart" :key="item.key" class="booking-item">
              <div class="booking-row"><div><strong>{{ item.slot.name }}</strong><small>{{ stamp(item) }}</small><small>{{ departmentName(attributes(item).department_id) }} / {{ doctorName(attributes(item).doctor_user_id) }}</small></div><button type="button" class="btn btn-secondary remove" :aria-label="`${item.slot.name} ${stamp(item)}を削除`" @click="remove(item)">×</button></div>
              <div v-if="item.slot.slot_group === 'equipment'" class="booking-link"><span>紐付け先：{{ parentFor(item) ? `${parentFor(item).slot.name} ${timeLabel(parentFor(item).scheduled_at)}` : 'なし' }}</span><button type="button" class="btn btn-secondary compact" @click="editLink(item)">変更</button></div>
            </article>
          </div>
        </section>
        <!-- DB登録済み予約を、今回の未登録カートと区別して表示する。 -->
        <section class="reservation-panel" aria-label="登録済み予約">
          <header class="panel-head"><h1>登録済み予約</h1><span>{{ data.appointments.length }}件</span></header>
          <div class="panel-scroll booking-list">
            <p v-if="!data.appointments.length" class="empty">登録済み予約はありません。</p>
            <article v-for="item in data.appointments" :key="item.id" class="existing-item"><strong>{{ item.reservation_slot_name || item.equipment_name || '診察予約' }}</strong><small>{{ stamp(item) }}</small><small>{{ item.department_name }} / {{ item.doctor_name || '医師未定' }}</small><small v-if="item.parent_appointment_id">診察予約に紐付け済み</small></article>
          </div>
        </section>
      </div>
    </section>
    <footer class="reservation-foot"><span>予約対象 {{ cart.length }}件</span><div class="buttons"><button type="button" class="btn btn-primary" :disabled="!cart.length || saving" @click="showModal('register')">登録</button><button type="button" class="btn btn-secondary" :disabled="saving" @click="close">閉じる</button></div></footer>
    <!-- 時間選択後の診療科・医師設定、登録前の最終確認、破棄確認を共通dialogで扱う。 -->
    <dialog ref="modal" class="reservation-modal" @cancel.prevent="dismiss">
      <template v-if="modalKind === 'entry' && draft">
        <header class="modal-head"><h2>時間枠を確定</h2></header>
        <form @submit.prevent="confirmEntry">
          <div class="modal-body"><p><strong>{{ draft.slot.name }}</strong><br>{{ stamp(draft) }}</p>
            <div class="entry-grid">
              <label v-if="draft.slot.slot_group === 'equipment'" class="wide">紐付け先診察予約<select v-model="draft.parent_entry_key" class="form-select" @change="inheritParent"><option value="">紐付けない（設備のみ）</option><option v-for="parent in parents" :key="parent.key" :value="parent.key">{{ parent.slot.name }} {{ stamp(parent) }}</option></select></label>
              <label>診療科 <span class="required">＊</span><select v-model="draft.department_id" class="form-select" :disabled="!!draft.parent_entry_key" required @change="resetDoctor"><option value="">選択してください</option><option v-for="department in data.departments" :key="department.id" :value="department.id">{{ department.name }}</option></select></label>
              <label>担当医<select v-model="draft.doctor_user_id" aria-label="担当医" class="form-select" :disabled="!!draft.parent_entry_key"><option value="">医師未定</option><option v-for="doctor in doctors" :key="doctor.id" :value="doctor.id">{{ doctor.name }}</option></select></label>
            </div><p v-if="dialogError" class="error" role="alert">{{ dialogError }}</p>
          </div>
          <footer class="modal-foot"><button class="btn btn-primary">確定</button><button type="button" class="btn btn-secondary" @click="dismiss">閉じる</button></footer>
        </form>
      </template>
      <template v-else-if="modalKind === 'register'">
        <header class="modal-head"><h2>予約内容の確認</h2></header><div class="modal-body"><p>{{ data.patient.last_name }} {{ data.patient.first_name }} さん</p><ul><li v-for="item in cart" :key="item.key">{{ item.slot.name }}　{{ stamp(item) }}<small>{{ departmentName(attributes(item).department_id) }} / {{ doctorName(attributes(item).doctor_user_id) }}</small></li></ul><p v-if="dialogError" class="error" role="alert">{{ dialogError }}</p></div>
        <footer class="modal-foot"><button class="btn btn-primary" :disabled="saving" @click="save">{{ saving ? '登録中…' : '登録' }}</button><button class="btn btn-secondary" :disabled="saving" @click="dismiss">戻る</button></footer>
      </template>
      <template v-else-if="modalKind === 'discard'"><header class="modal-head"><h2>予約内容を破棄しますか？</h2></header><div class="modal-body">登録していない予約内容が残っています。</div><footer class="modal-foot"><button class="btn btn-secondary" @click="leave">破棄して閉じる</button><button class="btn btn-secondary" @click="dismiss">戻る</button></footer></template>
    </dialog>
  </main>
</template>

<style scoped>
.reservation-workspace{display:flex;flex:1;flex-direction:column;min-width:0;min-height:0;height:100%;box-sizing:border-box;padding:14px 18px 0;color:#212529;overflow:hidden}
.reservation-layout{display:grid;grid-template-columns:190px minmax(0,1fr) 290px;gap:12px;flex:1;min-height:0;margin-top:12px}
.reservation-panel{display:flex;flex-direction:column;min-width:0;min-height:0;border:1px solid #aebac4;background:#fff;overflow:hidden}
.panel-head{display:flex;align-items:center;justify-content:space-between;gap:8px;flex:0 0 40px;padding:0 11px;border-bottom:1px solid #aebac4;background:#e5ebf0}.panel-head h1{margin:0;font-size:15px;font-weight:600}.panel-head span{color:#4e5c68;font-size:12px;white-space:nowrap}
.panel-scroll{flex:1;min-height:0;overflow:auto;overscroll-behavior:contain}.slot-tree summary{padding:8px 10px;background:#f4f6f8;color:#334654;font-size:13px;font-weight:600;cursor:pointer}.slot-choice{display:flex;align-items:flex-start;gap:8px;padding:8px 10px 8px 26px;border-bottom:1px solid #e0e7ec;cursor:pointer}.slot-choice input{width:17px;height:17px;margin-top:2px;flex-shrink:0;accent-color:#0b5ed7}.slot-choice span{min-width:0;overflow-wrap:anywhere}
.week-controls{display:flex;align-items:flex-end;gap:8px;flex-shrink:0;padding:8px 10px;border-bottom:1px solid #cbd6de}.week-controls label{display:grid;gap:4px;font-size:12px;color:#405261}.week-controls input{width:142px;height:34px}.slot-tabs{display:flex;flex-shrink:0;gap:3px;overflow:auto;padding:8px 8px 0;max-height:76px}.slot-tabs button{flex-shrink:0;max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;min-height:32px;padding:4px 10px;border:1px solid #9eafb9;background:#f5f7f8;color:#263746;font-size:13px}.slot-tabs button.active{border:2px solid #0b5ed7;border-bottom:0;background:#eef5fb;font-weight:600}
.week-calendar{width:100%;table-layout:fixed;border-collapse:separate;border-spacing:0;font-size:12px}.week-calendar th,.week-calendar td{text-align:center;border-right:1px solid #dbe3e9;border-bottom:1px solid #dbe3e9;padding:0}.week-calendar thead th{position:sticky;top:0;z-index:1;height:40px;background:#f4f6f8;color:#465563;font-weight:400}.week-calendar th:first-child{width:46px;background:#f8fafb;color:#4e5c68;font-weight:400}.week-calendar td{height:46px}.time-cell{width:calc(100% - 6px);min-height:32px;margin:3px;padding:2px;border:1px solid #8eacc3;background:#fff;color:#214a65;font-size:12px}.time-cell:hover,.time-cell.selected{border-color:#0b5ed7;background:#e8f2ff}.time-cell:disabled:not(.selected){border-color:#d3d7da;background:#edf0f2;color:#777}.unavailable{color:#8a969f}
.reservation-right{display:grid;grid-template-rows:minmax(0,1fr) minmax(0,1fr);gap:12px;min-width:0;min-height:0}.booking-list{padding:9px}.booking-item{padding:7px;margin-bottom:7px;border:1px solid #cbd7df;background:#f8fafb;overflow-wrap:anywhere}.booking-row{display:grid;grid-template-columns:minmax(0,1fr) 24px;gap:6px}.booking-item strong,.existing-item strong{display:block;font-size:13px}.booking-list small,.reservation-modal small{display:block;color:#4e5c68;font-size:12px}.booking-link{display:flex;align-items:center;justify-content:space-between;gap:6px;margin-top:6px;padding-top:5px;border-top:1px solid #dce4e9;color:#405261;font-size:12px}.booking-link span{min-width:0}.btn.remove{width:24px;min-width:24px;height:24px;min-height:0;padding:0;font-size:18px;line-height:1}.btn.compact{min-width:40px;min-height:25px;padding:1px 6px;font-size:12px}.existing-item{padding:8px 0;border-bottom:1px solid #e0e7ec;overflow-wrap:anywhere}.empty{margin:0;padding:14px;color:#59636e;font-size:13px}
.reservation-foot{display:flex;flex:0 0 auto;align-items:center;justify-content:space-between;margin-top:12px;padding:10px 0;border-top:1px solid #8999a6;font-size:13px}.buttons,.modal-foot{display:flex;gap:8px}.reservation-message{flex-shrink:0;margin:10px 0 0;padding:8px 12px;background:#fff;border-left:3px solid #26713c}.error{color:#b02a37}.reservation-message.error{border-color:#b02a37}
.reservation-modal{width:min(480px,calc(100vw - 32px));max-height:calc(100dvh - 48px);padding:0;border:1px solid #7b858f;background:#fff;color:#212529;box-shadow:0 6px 20px #0003}.reservation-modal::backdrop{background:#29323b80}.modal-head{padding:12px 16px;background:#e5ebf0;border-bottom:1px solid #aebac4}.modal-head h2{margin:0;font-size:17px}.modal-body{padding:16px;max-height:60vh;overflow:auto}.modal-body p{margin:0 0 12px}.entry-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.entry-grid label{display:block;font-size:13px}.entry-grid select{margin-top:4px;min-width:0;width:100%}.entry-grid .wide{grid-column:1/-1}.required{color:#b02a37}.modal-foot{justify-content:flex-end;padding:10px 16px;border-top:1px solid #aebac4;background:#f1f3f5}.modal-body li{margin-bottom:8px}.reservation-workspace button:focus-visible,.slot-choice input:focus-visible{outline:2px solid #0b5ed7;outline-offset:2px}
@media(max-width:1000px){.reservation-layout{grid-template-columns:160px minmax(0,1fr) 250px;gap:8px}.reservation-workspace{padding:12px 12px 0}.panel-head{padding:0 8px}}
@media(max-width:760px){.reservation-layout{grid-template-columns:1fr;overflow:auto}.reservation-layout>.reservation-panel{min-height:230px}.reservation-layout>.reservation-panel:nth-child(2){min-height:380px}.reservation-right{min-height:440px}.reservation-foot{gap:8px}.slot-choice{padding:6px 14px}}
</style>
