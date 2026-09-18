<script setup>
// 患者検索から遷移する受付登録画面。予約採用と予約なし受付の入力状態を一画面で管理する。
// API呼出は receptions/api.js に集約し、登録成功時だけ外来一覧へ遷移する。
import { computed, onMounted, ref } from 'vue'
import PatientBanner from '../../../shared/components/PatientBanner.vue'
import { loadReceptionCandidates, registerReceptions } from '../api.js'

const props = defineProps({ modal: { type: Boolean, default: false }, patientId: { type: [String, Number], default: null } })
const emit = defineEmits(['completed', 'cancelled'])

const patient = ref(null), appointments = ref([]), departments = ref([]), selectedIds = ref([]), doctorOverrides = ref({})
const unreserved = ref([]), loading = ref(true), saving = ref(false), message = ref(''), error = ref(false), results = ref([])
const patientId = computed(() => props.patientId || new URLSearchParams(location.search).get('patient_id'))
const selectedAppointments = computed(() => appointments.value.filter(item => selectedIds.value.includes(item.id)))
const receptionCount = computed(() => selectedAppointments.value.length + unreserved.value.length)
const doctorFor = item => item.doctor_name || doctorOverrides.value[item.id] || ''

function addUnreserved() { unreserved.value.push({ key: crypto.randomUUID(), department_id: '', doctor_name: '' }) }
function removeUnreserved(key) { unreserved.value = unreserved.value.filter(item => item.key !== key) }
function close() { if (props.modal) emit('cancelled'); else window.location.assign('/patients') }
function goOutpatients() { if (props.modal) emit('completed', results.value); else window.location.assign('/outpatients') }

async function load() {
  if (!patientId.value) { error.value = true; message.value = '患者を選択してから受付を開始してください。'; loading.value = false; return }
  try {
    const data = await loadReceptionCandidates(patientId.value)
    patient.value = data.patient; appointments.value = data.appointments; departments.value = data.departments
  } catch (cause) { error.value = true; message.value = cause.message || '受付候補を取得できませんでした。' }
  finally { loading.value = false }
}

async function submit() {
  if (saving.value || !receptionCount.value) return
  saving.value = true; message.value = ''; error.value = false
  const targets = [
    ...selectedAppointments.value.map(item => ({ type: 'appointment', appointment_id: item.id, doctor_name: doctorFor(item) })),
    ...unreserved.value.map(item => ({ type: 'unreserved', department_id: Number(item.department_id), doctor_name: item.doctor_name })),
  ]
  try {
    const response = await registerReceptions({ patient_id: patient.value.id, targets })
    results.value = response.receptions
    message.value = '受付を登録しました。外来一覧で次の業務へ進められます。'
  } catch (cause) { error.value = true; message.value = cause.message || '受付を登録できませんでした。' }
  finally { saving.value = false }
}

onMounted(load)
</script>

<template>
  <div :class="{ 'workflow-overlay': modal }">
  <header class="app-head"><strong>外来業務</strong><span>受付登録</span></header>
  <main class="reception-workspace">
    <p v-if="patient" class="reception-breadcrumb">患者検索　›　患者No. {{ patient.patient_number }}　›　外来受付</p>
    <PatientBanner v-if="patient" :patient="patient" />
    <p v-if="loading" class="reception-message" role="status">受付候補を読み込んでいます。</p>
    <p v-else-if="!patient" class="reception-message reception-message--error" role="alert">{{ message }}</p>
    <template v-else>
      <p class="reception-instruction"><strong>受付対象を選択してください。</strong>診察予約は複数選択できます。選択した診察ごとに別の受付No.を発行し、付随する設備予約は同じ受付へ引き継ぎます。</p>
      <p v-if="message" :class="['reception-message', { 'reception-message--error': error }]" role="status">{{ message }}</p>
      <section class="reception-layout">
        <section class="reception-panel" aria-labelledby="appointment-reception"><div class="reception-panel__head"><h1 id="appointment-reception">予約から受付</h1><span>選択した予約ごとに受付No.を発番します</span></div>
          <div class="appointment-list"><p v-if="!appointments.length" class="empty">本日の未受付予約はありません。</p><table v-else><thead><tr><th>受付</th><th>時刻</th><th>種別</th><th>診療科 / 設備</th><th>担当医</th><th>付随予約・補足</th></tr></thead><tbody><tr v-for="item in appointments" :key="item.id"><td><input v-model="selectedIds" type="checkbox" :value="item.id" :aria-label="`${item.department_name}を受付対象に選択`"></td><td class="time">{{ new Date(item.scheduled_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' }) }}</td><td><span class="kind">{{ item.kind === 'consultation' ? '診察' : '設備' }}</span></td><td>{{ item.kind === 'equipment' ? `${item.equipment_name}（${item.department_name}）` : item.department_name }}</td><td><label v-if="item.kind === 'consultation' && !item.doctor_name" class="doctor-select"><input v-model="doctorOverrides[item.id]" :disabled="!selectedIds.includes(item.id)" maxlength="100" placeholder="医師名を入力"></label><span v-else>{{ item.doctor_name || '－' }}</span></td><td>{{ item.attached_equipment.length ? item.attached_equipment.map(child => `${child.name} ${new Date(child.scheduled_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })}`).join(' / ') : item.kind === 'equipment' ? '設備のみの予約' : '－' }}</td></tr></tbody></table></div>
        </section>
        <section class="reception-panel" aria-labelledby="unreserved-reception"><div class="reception-panel__head"><h1 id="unreserved-reception">予約なし受付</h1><button type="button" class="btn btn-secondary" @click="addUnreserved">行を追加</button></div><p class="panel-note">診療科と医師を指定して、当日受付を追加します。</p><div class="unreserved-list"><p v-if="!unreserved.length" class="empty">予約なし受付は追加されていません。</p><div v-for="item in unreserved" :key="item.key" class="unreserved-row"><label>診療科 <select v-model="item.department_id" class="form-select"><option value="">選択してください</option><option v-for="department in departments" :key="department.id" :value="department.id">{{ department.name }}</option></select></label><label>医師 <input v-model="item.doctor_name" class="form-control" maxlength="100" placeholder="医師名を入力"></label><button type="button" class="btn btn-secondary" @click="removeUnreserved(item.key)">削除</button></div></div></section>
      </section>
      <div v-if="results.length" class="reception-complete" role="dialog" aria-modal="true" aria-label="受付登録結果"><section><h2>受付登録が完了しました</h2><p><strong>{{ patient.last_name }} {{ patient.first_name }}</strong> さんの受付を登録しました。</p><ul><li v-for="item in results" :key="item.id">{{ item.department_name }}：受付No. {{ item.reception_number }}</li></ul><div class="buttons"><button type="button" class="btn btn-primary" @click="goOutpatients">OK</button></div></section></div>
      <footer class="reception-foot"><span>受付対象 {{ receptionCount }}件 / 発番予定 {{ receptionCount }}件</span><div class="buttons"><button type="button" class="btn btn-primary" :disabled="saving || !receptionCount || results.length" @click="submit">{{ saving ? '登録中…' : '受付' }}</button><button type="button" class="btn btn-secondary" @click="close">閉じる</button></div></footer>
    </template>
  </main>
  </div>
</template>

<style scoped>
.reception-workspace{margin:14px auto;max-width:1320px;padding:0 20px 76px}.reception-breadcrumb{margin:0 0 10px;color:#526170;font-size:12px}.reception-instruction{margin:14px 0 10px;padding:9px 12px;border-left:4px solid #496c87;background:#f7fafc;color:#3f515f}.reception-instruction strong{color:#263c4d;margin-right:8px}.reception-message{margin:12px 0;padding:9px 12px;background:#fff;border-left:3px solid #26713c}.reception-message--error{border-color:#b02a37;color:#8d1f2a}.reception-layout{display:grid;grid-template-columns:minmax(0,1.65fr) minmax(340px,.9fr);gap:14px}.reception-panel{background:#fff;border:1px solid #aebac4}.reception-panel__head{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:9px 12px;background:#e5ebf0;border-bottom:1px solid #aebac4}.reception-panel__head h1{margin:0;font-size:15px}.reception-panel__head span,.panel-note{font-size:12px;color:#4e5c68}.panel-note{margin:10px 12px}.appointment-list table{width:100%;border-collapse:collapse}.appointment-list th,.appointment-list td{padding:8px 7px;border-bottom:1px solid #dce3e8;text-align:left;white-space:nowrap}.appointment-list th{background:#f4f6f8;color:#465563;font-size:12px}.appointment-list input[type=checkbox]{width:17px;height:17px;accent-color:#0b5ed7}.time{font-variant-numeric:tabular-nums;font-weight:600}.kind{display:inline-block;padding:2px 6px;border:1px solid #9eb0bf;border-radius:2px;background:#f5f8fa;color:#3d556a;font-size:12px}.doctor-select input{width:120px;height:30px;border:1px solid #98a8b6;padding:3px 6px}.empty{margin:0;padding:16px;color:#59636e}.unreserved-list{display:flex;flex-direction:column;gap:8px;padding:0 12px 12px}.unreserved-row{display:grid;grid-template-columns:1fr 1fr auto;gap:8px;align-items:end;padding:9px;background:#f8f9fa;border:1px solid #dee2e6}.unreserved-row label{display:flex;flex-direction:column;gap:4px;font-size:12px}.reception-foot{position:fixed;right:0;bottom:0;left:0;z-index:4;display:flex;justify-content:space-between;align-items:center;padding:10px max(20px,calc((100vw - 1280px)/2 + 20px));background:#fff;border-top:1px solid #8999a6;box-shadow:0 -2px 8px #182a381f;font-size:13px}.reception-complete{position:fixed;inset:0;z-index:30;display:grid;place-items:center;background:#29323b80}.reception-complete section{width:min(480px,calc(100vw - 32px));padding:20px;background:#fff;border:1px solid #7b858f;box-shadow:0 6px 20px #0003}.reception-complete h2{margin:0 0 14px;font-size:18px}.reception-complete ul{margin:12px 0 18px;padding-left:22px}.reception-complete .buttons{justify-content:flex-end}@media(max-width:960px){.reception-workspace{padding:0 10px 76px}.reception-layout{grid-template-columns:1fr}.appointment-list{overflow:auto}.appointment-list table{min-width:720px}.reception-foot{padding:10px 16px}}@media(max-width:620px){.reception-foot{gap:8px;align-items:flex-end}.reception-foot>span{max-width:42%}}
</style>
