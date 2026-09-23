<script setup>
// ReservationSlotMasterPaneから編集IDと有効な選択肢を受けるフォーム。Vueは入力・未保存確認、Railsは最終検証・SQLite保存を担う。
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { ApiError } from '../../../../shared/api/http.js'
import { loadReservationSlot, saveReservationSlot } from '../api.js'

const props = defineProps({ slotId: { type: Number, default: null }, departments: { type: Array, required: true }, doctors: { type: Array, required: true } })
const emit = defineEmits(['close', 'dirty-change'])
const form = ref(), resume = ref()
const busy = ref(false), loadFailed = ref(false), uncertain = ref(false), discard = ref(false)
const message = ref(''), errors = ref({}), original = ref(''), number = ref('自動採番（保存時）')
const currentDepartmentName = ref(''), currentDoctorName = ref('')
const hydrating = ref(false)
const values = reactive({ name: '', slot_group: 'consultation', weekdays: [1, 2, 3, 4, 5], valid_from: '', valid_to: '', start_time: '09:00', end_time: '12:00', interval_minutes: 30, capacity: 1, default_department_id: '', default_doctor_user_id: '', display_order: 0, active: true, lock_version: null, schedule_editable: true })
const dirty = computed(() => JSON.stringify(values) !== original.value)
const filteredDoctors = computed(() => !values.default_department_id ? props.doctors : props.doctors.filter(doctor => !doctor.department_id || String(doctor.department_id) === String(values.default_department_id)))
const departmentOptions = computed(() => {
  const current = values.default_department_id
  if (!current || props.departments.some(department => String(department.id) === String(current))) return props.departments
  return [{ id: current, name: `停止中: ${currentDepartmentName.value || '不明な診療科'}` }, ...props.departments]
})
const doctorOptions = computed(() => {
  const current = values.default_doctor_user_id
  if (!current || filteredDoctors.value.some(doctor => String(doctor.id) === String(current))) return filteredDoctors.value
  return [{ id: current, name: `停止中: ${currentDoctorName.value || '不明な医師'}` }, ...filteredDoctors.value]
})
const weekdays = [{ value: 1, label: '月' }, { value: 2, label: '火' }, { value: 3, label: '水' }, { value: 4, label: '木' }, { value: 5, label: '金' }, { value: 6, label: '土' }, { value: 7, label: '日' }]
const scheduleDisabled = computed(() => props.slotId && !values.schedule_editable)

function snapshot() { return JSON.stringify(values) }
function focusFirst() { form.value?.querySelector('#reservation-slot-name')?.focus() }
function beforeUnload(event) { if (dirty.value || busy.value) { event.preventDefault(); event.returnValue = '' } }
function normalizeForSave() { return { ...values, default_department_id: values.default_department_id || null, default_doctor_user_id: values.default_doctor_user_id || null } }
function doctorName(id) { return props.doctors.find(doctor => String(doctor.id) === String(id))?.name || '—' }

async function close() {
  if (busy.value) return false
  if (!dirty.value) { emit('close'); return true }
  discard.value = true
  await nextTick()
  resume.value?.focus()
  return false
}
async function resumeEdit() { discard.value = false; await nextTick(); focusFirst() }
function handleKeydown(event) {
  if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault()
  if (event.key === 'Escape') { event.preventDefault(); close() }
}
async function save() {
  if (busy.value || discard.value || loadFailed.value || uncertain.value) return
  busy.value = true; errors.value = {}; message.value = ''
  try {
    const slot = await saveReservationSlot(props.slotId, normalizeForSave())
    original.value = snapshot()
    emit('close', slot)
  } catch (error) {
    if (error instanceof ApiError && error.status < 500) { errors.value = error.errors; message.value = error.message }
    else { uncertain.value = true; message.value = '保存結果を確認できません。自動再送はしません。登録済みかを確認してから操作してください。' }
  } finally {
    busy.value = false
    await nextTick()
    form.value?.querySelector('[aria-invalid="true"]')?.focus()
  }
}

watch(dirty, value => emit('dirty-change', value), { immediate: true })
watch(() => values.default_department_id, () => {
  // 詳細取得中は停止済みの既存医師を表示用に保持する。利用者による診療科変更時だけ候補外を解除する。
  if (hydrating.value) return
  if (values.default_doctor_user_id && !filteredDoctors.value.some(doctor => String(doctor.id) === String(values.default_doctor_user_id))) values.default_doctor_user_id = ''
})
onMounted(async () => {
  original.value = snapshot()
  window.addEventListener('beforeunload', beforeUnload)
  if (props.slotId) {
    busy.value = true
    try {
      const slot = await loadReservationSlot(props.slotId)
      hydrating.value = true
      for (const key of Object.keys(values)) values[key] = slot[key] ?? values[key]
      values.default_department_id = slot.default_department_id || ''
      values.default_doctor_user_id = slot.default_doctor_user_id || ''
      currentDepartmentName.value = slot.default_department_name || ''
      currentDoctorName.value = slot.default_doctor_name || ''
      number.value = slot.id
      original.value = snapshot()
    } catch (error) { loadFailed.value = true; message.value = error.message || '読み込みに失敗しました。閉じてから再度開いてください。' }
    finally { busy.value = false }
  }
  await nextTick()
  hydrating.value = false
  if (loadFailed.value) form.value?.querySelector('#reservation-slot-close')?.focus()
  else focusFirst()
})
onBeforeUnmount(() => { window.removeEventListener('beforeunload', beforeUnload); emit('dirty-change', false) })

// 親の左ナビ切替時に呼ばれる。未保存なら同じ破棄確認を表示し、確定後のcloseイベントで親へ戻る。
defineExpose({ close, doctorName })
</script>

<template>
  <section class="master-form reservation-slot-form" aria-labelledby="reservation-slot-dialog-title">
    <header class="dialog-head"><h2 id="reservation-slot-dialog-title">{{ slotId ? '予約枠編集' : '予約枠登録' }}</h2><span class="mode">{{ slotId ? '編集' : '新規' }}</span></header>
    <form ref="form" novalidate @submit.prevent="save" @keydown="handleKeydown">
      <div class="dialog-body">
        <div class="identity">枠ID <strong>{{ number }}</strong><span>基本情報</span></div>
        <p v-if="message" class="form-message" role="alert">{{ message }}</p><p v-if="busy" role="status">処理中です…</p>
        <p v-if="scheduleDisabled" class="form-message reservation-slot-form__notice">予約に使用された枠です。曜日・期間・時間・定員は変更できません。</p>
        <p class="section-heading">基本情報</p>
        <fieldset class="fields" :disabled="busy || loadFailed">
          <div class="field field-wide"><label for="reservation-slot-name">枠名<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-name" v-model="values.name" class="form-control" maxlength="100" required autocomplete="off" :aria-invalid="!!errors.name" aria-describedby="reservation-slot-name-error"><p id="reservation-slot-name-error" class="field-error">{{ errors.name?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-group">枠グループ<span class="required" aria-label="必須">＊</span></label><div><select id="reservation-slot-group" v-model="values.slot_group" class="form-select" :disabled="scheduleDisabled" :aria-invalid="!!errors.slot_group" aria-describedby="reservation-slot-group-error"><option value="consultation">診察</option><option value="equipment">設備</option></select><p id="reservation-slot-group-error" class="field-error">{{ errors.slot_group?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-active">利用状態<span class="required" aria-label="必須">＊</span></label><div><select id="reservation-slot-active" v-model="values.active" class="form-select" :aria-invalid="!!errors.active" aria-describedby="reservation-slot-active-error"><option :value="true">有効</option><option :value="false">無効</option></select><p id="reservation-slot-active-error" class="field-error">{{ errors.active?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-display-order">表示順<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-display-order" v-model.number="values.display_order" class="form-control" type="number" min="0" required inputmode="numeric" :aria-invalid="!!errors.display_order" aria-describedby="reservation-slot-display-order-error"><p id="reservation-slot-display-order-error" class="field-error">{{ errors.display_order?.join(' ') }}</p></div></div>
        </fieldset>
        <p class="section-heading">利用日・時間</p>
        <fieldset class="fields" :disabled="busy || loadFailed || scheduleDisabled">
          <div class="field field-wide"><span class="reservation-slot-form__label">曜日<span class="required" aria-label="必須">＊</span></span><div><div class="reservation-slot-form__days"><label v-for="day in weekdays" :key="day.value"><input v-model="values.weekdays" type="checkbox" :value="day.value">{{ day.label }}</label></div><p class="field-error">{{ errors.weekdays?.join(' ') || errors.weekdays_mask?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-valid-from">有効開始日<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-valid-from" v-model="values.valid_from" class="form-control" type="date" required :aria-invalid="!!errors.valid_from" aria-describedby="reservation-slot-valid-from-error"><p id="reservation-slot-valid-from-error" class="field-error">{{ errors.valid_from?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-valid-to">有効終了日<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-valid-to" v-model="values.valid_to" class="form-control" type="date" required :aria-invalid="!!errors.valid_to" aria-describedby="reservation-slot-valid-to-error"><p id="reservation-slot-valid-to-error" class="field-error">{{ errors.valid_to?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-start">開始時刻<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-start" v-model="values.start_time" class="form-control" placeholder="09:00" required :aria-invalid="!!(errors.start_time || errors.start_minute)" aria-describedby="reservation-slot-start-error"><p id="reservation-slot-start-error" class="field-error">{{ errors.start_time?.join(' ') || errors.start_minute?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-end">終了時刻<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-end" v-model="values.end_time" class="form-control" placeholder="12:00（24:00可）" required :aria-invalid="!!(errors.end_time || errors.end_minute)" aria-describedby="reservation-slot-end-error"><p id="reservation-slot-end-error" class="field-error">{{ errors.end_time?.join(' ') || errors.end_minute?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-interval">間隔（分）<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-interval" v-model.number="values.interval_minutes" class="form-control" type="number" min="1" required inputmode="numeric" :aria-invalid="!!errors.interval_minutes" aria-describedby="reservation-slot-interval-error"><p id="reservation-slot-interval-error" class="field-error">{{ errors.interval_minutes?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-capacity">各枠定員（人）<span class="required" aria-label="必須">＊</span></label><div><input id="reservation-slot-capacity" v-model.number="values.capacity" class="form-control" type="number" min="1" required inputmode="numeric" :aria-invalid="!!errors.capacity" aria-describedby="reservation-slot-capacity-error"><p id="reservation-slot-capacity-error" class="field-error">{{ errors.capacity?.join(' ') }}</p></div></div>
        </fieldset>
        <p class="field-help reservation-slot-form__help">{{ values.interval_minutes || '—' }}分ごとの各枠に{{ values.capacity || '—' }}人まで。診療科・医師によらず定員を共有します。</p>
        <p class="section-heading">予約の初期値</p>
        <fieldset class="fields" :disabled="busy || loadFailed">
          <div class="field"><label for="reservation-slot-department">初期診療科</label><div><select id="reservation-slot-department" v-model="values.default_department_id" class="form-select" :aria-invalid="!!errors.default_department_id" aria-describedby="reservation-slot-department-error"><option value="">未設定</option><option v-for="department in departmentOptions" :key="department.id" :value="department.id">{{ department.name }}</option></select><p id="reservation-slot-department-error" class="field-error">{{ errors.default_department_id?.join(' ') }}</p></div></div>
          <div class="field"><label for="reservation-slot-doctor">初期医師</label><div><select id="reservation-slot-doctor" v-model="values.default_doctor_user_id" class="form-select" :aria-invalid="!!errors.default_doctor_user_id" aria-describedby="reservation-slot-doctor-error"><option value="">未設定</option><option v-for="doctor in doctorOptions" :key="doctor.id" :value="doctor.id">{{ doctor.name }}</option></select><p id="reservation-slot-doctor-error" class="field-error">{{ errors.default_doctor_user_id?.join(' ') }}</p></div></div>
        </fieldset>
        <p class="field-help reservation-slot-form__help">初期値は予約時に変更できます。予約取得では診療科が必須、医師は未設定でも登録できます。</p>
        <section v-if="discard" class="discard" role="alert"><p><span aria-hidden="true">⚠</span> 入力中の変更を破棄して閉じますか？</p><div class="buttons"><button ref="resume" type="button" class="btn btn-secondary" @click="resumeEdit">戻る</button><button type="button" class="btn btn-secondary" @click="emit('close')"><span aria-hidden="true">⚠</span> 中止</button></div></section>
      </div>
      <footer class="dialog-foot"><span>＊ 必須項目</span><div class="buttons"><button type="submit" class="btn btn-primary" :disabled="busy || discard || loadFailed || uncertain">登録</button><button id="reservation-slot-close" type="button" class="btn btn-secondary" :disabled="busy" @click="close">閉じる</button></div></footer>
    </form>
  </section>
</template>

<style scoped>
.reservation-slot-form__notice{margin-bottom:12px}.reservation-slot-form__label{padding-top:7px;white-space:nowrap}.reservation-slot-form__days{display:flex;gap:14px;min-height:35px;align-items:center;flex-wrap:wrap}.reservation-slot-form__days label{display:flex;align-items:center;gap:4px;white-space:nowrap}.reservation-slot-form__help{margin-left:92px}@media(max-width:560px){.reservation-slot-form__help{margin-left:88px}}
</style>
