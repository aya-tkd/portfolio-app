<script setup>
// 患者検索から遷移する受付登録画面。予約採用と予約なし受付の入力状態を一画面で管理する。
// API呼出は receptions/api.js に集約し、登録成功時だけ外来一覧へ遷移する。
import { computed, onMounted, ref } from 'vue'
import PatientBanner from '../../../shared/components/PatientBanner.vue'
import { loadReceptionCandidates, registerReceptions } from '../api.js'

const patient = ref(null), appointments = ref([]), departments = ref([]), selectedIds = ref([]), doctorOverrides = ref({})
const unreserved = ref([]), loading = ref(true), saving = ref(false), message = ref(''), error = ref(false), results = ref([])
const patientId = new URLSearchParams(location.search).get('patient_id')
const selectedAppointments = computed(() => appointments.value.filter(item => selectedIds.value.includes(item.id)))
const receptionCount = computed(() => selectedAppointments.value.length + unreserved.value.length)
const doctorFor = item => item.doctor_name || doctorOverrides.value[item.id] || ''

function addUnreserved() { unreserved.value.push({ key: crypto.randomUUID(), department_id: '', doctor_name: '' }) }
function removeUnreserved(key) { unreserved.value = unreserved.value.filter(item => item.key !== key) }
function close() { window.location.assign('/patients') }
function goOutpatients() { window.location.assign('/outpatients') }

async function load() {
  if (!patientId) { error.value = true; message.value = '患者を選択してから受付を開始してください。'; loading.value = false; return }
  try {
    const data = await loadReceptionCandidates(patientId)
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
  <header class="app-head"><strong>外来業務</strong><span>受付登録</span></header>
  <main class="reception-workspace">
    <PatientBanner v-if="patient" :patient="patient" />
    <p v-if="loading" class="reception-message" role="status">受付候補を読み込んでいます。</p>
    <p v-else-if="!patient" class="reception-message reception-message--error" role="alert">{{ message }}</p>
    <template v-else>
      <p v-if="message" :class="['reception-message', { 'reception-message--error': error }]" role="status">{{ message }}</p>
      <section class="reception-layout">
        <section class="reception-panel" aria-labelledby="appointment-reception"><div class="reception-panel__head"><h1 id="appointment-reception">予約から受付</h1><span>選択した予約ごとに受付No.を発番します</span></div>
          <div class="appointment-list"><p v-if="!appointments.length" class="empty">本日の未受付予約はありません。</p><article v-for="item in appointments" :key="item.id" class="appointment-row"><label class="appointment-row__select"><input v-model="selectedIds" type="checkbox" :value="item.id"><span>{{ item.kind === 'consultation' ? '診察予約' : '設備予約' }}</span></label><span>{{ new Date(item.scheduled_at).toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' }) }}</span><strong>{{ item.department_name }}</strong><span>{{ item.kind === 'equipment' ? item.equipment_name : '診察' }}</span><label v-if="item.kind === 'consultation' && !item.doctor_name" class="doctor-select">医師 <input v-model="doctorOverrides[item.id]" :disabled="!selectedIds.includes(item.id)" maxlength="100" placeholder="医師名を入力"></label><span v-else>{{ item.doctor_name || '医師指定なし' }}</span><small v-if="item.attached_equipment.length">付随設備: {{ item.attached_equipment.map(child => child.name).join(' / ') }}</small></article></div>
        </section>
        <section class="reception-panel" aria-labelledby="unreserved-reception"><div class="reception-panel__head"><h1 id="unreserved-reception">予約なし受付</h1><button type="button" class="btn btn-secondary" @click="addUnreserved">行を追加</button></div><p class="panel-note">診療科と医師を指定して、当日受付を追加します。</p><div class="unreserved-list"><p v-if="!unreserved.length" class="empty">予約なし受付は追加されていません。</p><div v-for="item in unreserved" :key="item.key" class="unreserved-row"><label>診療科 <select v-model="item.department_id" class="form-select"><option value="">選択してください</option><option v-for="department in departments" :key="department.id" :value="department.id">{{ department.name }}</option></select></label><label>医師 <input v-model="item.doctor_name" class="form-control" maxlength="100" placeholder="医師名を入力"></label><button type="button" class="btn btn-secondary" @click="removeUnreserved(item.key)">削除</button></div></div></section>
      </section>
      <section v-if="results.length" class="result-panel reception-result" aria-label="登録結果"><h2>受付登録結果</h2><ul><li v-for="item in results" :key="item.id">{{ item.department_name }}：受付No. {{ item.reception_number }}</li></ul><button type="button" class="btn btn-secondary" @click="goOutpatients">外来一覧へ</button></section>
      <footer class="reception-foot"><span>受付対象 {{ receptionCount }}件 / 発番予定 {{ receptionCount }}件</span><div class="buttons"><button type="button" class="btn btn-primary" :disabled="saving || !receptionCount || results.length" @click="submit">{{ saving ? '登録中…' : '受付' }}</button><button type="button" class="btn btn-secondary" @click="close">閉じる</button></div></footer>
    </template>
  </main>
</template>

<style scoped>
.reception-workspace{margin:16px auto;max-width:1280px;padding:0 16px 76px}.reception-message{margin:12px 0;padding:9px 12px;background:#fff;border-left:3px solid #26713c}.reception-message--error{border-color:#b02a37;color:#8d1f2a}.reception-layout{display:grid;grid-template-columns:minmax(0,1.3fr) minmax(360px,.9fr);gap:14px;margin-top:14px}.reception-panel{background:#fff;border:1px solid #adb5bd}.reception-panel__head{display:flex;justify-content:space-between;align-items:center;gap:10px;padding:9px 12px;background:#e9ecef;border-bottom:1px solid #adb5bd}.reception-panel__head h1{margin:0;font-size:15px}.reception-panel__head span,.panel-note{font-size:12px;color:#4e5c68}.panel-note{margin:10px 12px}.appointment-row{display:grid;grid-template-columns:126px 56px 90px 92px minmax(130px,1fr);gap:10px;align-items:center;padding:9px 12px;border-bottom:1px solid #dee2e6}.appointment-row small{grid-column:2 / -1;color:#4e5c68}.appointment-row__select{display:flex;gap:7px;align-items:center;font-weight:600}.doctor-select{display:flex;gap:6px;align-items:center}.doctor-select input{min-width:0;height:31px;border:1px solid #adb5bd;padding:4px 6px}.empty{margin:0;padding:16px;color:#59636e}.unreserved-list{display:flex;flex-direction:column;gap:8px;padding:0 12px 12px}.unreserved-row{display:grid;grid-template-columns:1fr 1fr auto;gap:8px;align-items:end;padding:9px;background:#f8f9fa;border:1px solid #dee2e6}.unreserved-row label{display:flex;flex-direction:column;gap:4px;font-size:12px}.reception-result{margin-top:14px;padding-bottom:12px}.reception-result ul{margin:12px 18px}.reception-result button{margin-left:12px}.reception-foot{position:fixed;right:0;bottom:0;left:0;z-index:4;display:flex;justify-content:space-between;align-items:center;padding:10px max(16px,calc((100vw - 1248px)/2));background:#f8f9fa;border-top:1px solid #adb5bd;font-size:13px}@media(max-width:900px){.reception-layout{grid-template-columns:1fr}.appointment-row{grid-template-columns:126px 56px 90px 1fr}.appointment-row>span:last-of-type,.doctor-select{grid-column:4}.reception-foot{padding:10px 16px}}@media(max-width:620px){.appointment-row,.unreserved-row{grid-template-columns:1fr}.appointment-row small,.appointment-row>span:last-of-type,.doctor-select{grid-column:auto}.reception-foot{gap:8px;align-items:flex-end}.reception-foot>span{max-width:42%}}
</style>
