<script setup>
// App.vueから開く外来一覧。検索条件と設備行の開閉を保持し、保存成功時だけ該当行を置換する。
// 会計待ちの判定・次の操作はサーバーのDTOを使用し、FEへ業務ルールを複製しない。
import { nextTick, onMounted, ref } from 'vue'
import { advanceOutpatient, loadOutpatients } from '../api.js'
import PatientSearchWorkspace from '../../patients/components/PatientSearchWorkspace.vue'
import ReceptionWorkspace from '../../receptions/components/ReceptionWorkspace.vue'
import OutpatientWorkflowDialog from './OutpatientWorkflowDialog.vue'

const labels = { reserved: '予約', received: '受付済', called: '呼出済', consulting: '診察中', equipment_wait: '設備待ち', execution_wait: '実施待ち', billing_wait: '会計待ち', paid: '会計済' }
const actions = { call: '呼出', start: '診察開始', finish: '診察終了', complete: '実施' }
const date = ref(''), departmentId = ref(''), statuses = ref(Object.keys(labels))
const rows = ref([]), departments = ref([]), expanded = ref(new Set())
const busy = ref(false), message = ref(''), failed = ref(false), stale = ref(false), summary = ref(null), applied = ref('')
const activeWorkflow = ref(null), selectedPatientId = ref(null)

function openPatientSearch() { activeWorkflow.value = 'patient-search' }
function openReception(patient) { selectedPatientId.value = patient.id; activeWorkflow.value = 'reception' }
function closeWorkflow() { activeWorkflow.value = null; selectedPatientId.value = null }
async function completeReception() { closeWorkflow(); await search() }
const time = value => value ? new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', hour: '2-digit', minute: '2-digit', hour12: false }).format(new Date(value)) : '—'
const equipmentStatus = item => ({ reserved: '予約', waiting: '実施待ち', completed: '実施済' })[item.status]

function toggle(row) {
  const next = new Set(expanded.value)
  next.has(row.key) ? next.delete(row.key) : next.add(row.key)
  expanded.value = next
}

async function search() {
  if (busy.value) return
  busy.value = true; message.value = ''; failed.value = false
  try {
    if (!statuses.value.length) {
      rows.value = []; message.value = '進捗を1つ以上選択してください。'
    } else {
      const result = await loadOutpatients({ date: date.value, departmentId: departmentId.value, statuses: statuses.value })
      date.value ||= result.today
      rows.value = result.rows; departments.value = result.departments
    }
    applied.value = `${date.value} · ${departments.value.find(item => String(item.id) === String(departmentId.value))?.name || '全診療科'}`
    stale.value = false
  } catch (error) {
    message.value = error.message || '通信に失敗しました。'; failed.value = true; stale.value = true
  } finally { busy.value = false }
}

async function advance(row, action, equipmentId = null) {
  if (busy.value || stale.value) return
  busy.value = true; message.value = ''; failed.value = false
  try {
    const updated = await advanceOutpatient(row, action, equipmentId)
    rows.value = rows.value.map(item => item.key === row.key ? updated : item)
    message.value = `${row.patient_name}：${actions[action]}を記録しました。`
  } catch (error) {
    // タイムアウトでもサーバーだけ保存済みの可能性がある。再操作の前に再検索を要求する。
    message.value = `${error.message || '通信に失敗しました。'} 再検索して状態を確認してください。`
    failed.value = true; stale.value = true
  } finally {
    busy.value = false
    await nextTick()
    summary.value?.focus()
  }
}
onMounted(search)
</script>

<template>
  <div class="outpatient-app">
    <header class="outpatient-head"><strong>医療機関業務システム</strong><h1>外来一覧</h1></header>
    <div class="outpatient-layout">
      <nav class="outpatient-nav" aria-label="業務メニュー">
        <span class="nav-group">外来業務</span>
        <a href="/outpatients" aria-current="page"><span aria-hidden="true">▤</span>外来一覧</a>
        <button disabled><span aria-hidden="true">▦</span>予約<small>準備中</small></button>
        <button type="button" class="outpatient-nav-action" @click="openPatientSearch"><span aria-hidden="true">☑</span>受付</button>
        <button disabled><span aria-hidden="true">▣</span>会計<small>準備中</small></button>
        <div class="outpatient-admin"><span class="nav-group">管理</span><button disabled><span aria-hidden="true">⚙</span>マスタ設定<small>準備中</small></button></div>
      </nav>
      <main class="outpatient-main">
        <form class="outpatient-conditions" @submit.prevent="search">
          <fieldset :disabled="busy">
            <div class="outpatient-filters">
              <div class="outpatient-field"><label for="outpatient-date">診療日</label><input id="outpatient-date" v-model="date" type="date" required></div>
              <div class="outpatient-field"><label for="outpatient-department">診療科</label><select id="outpatient-department" v-model="departmentId"><option value="">すべて</option><option v-for="item in departments" :key="item.id" :value="item.id">{{ item.name }}</option></select></div>
              <button class="btn btn-secondary" type="submit">{{ busy ? '処理中…' : '検索' }}</button>
            </div>
            <div class="outpatient-progress" role="group" aria-label="進捗"><span>進捗</span><label v-for="(label, code) in labels" :key="code"><input v-model="statuses" type="checkbox" :value="code">{{ label }}</label></div>
          </fieldset>
        </form>
        <p v-if="message" :class="['outpatient-message', { error: failed }]" role="status">{{ message }}</p>
        <section class="outpatient-results" aria-label="外来患者">
          <div class="outpatient-results-head"><h2>外来患者</h2><span>{{ applied }}</span></div>
          <div class="outpatient-scroll" tabindex="0" role="region" aria-label="外来一覧・スクロール可能" :aria-busy="busy">
            <table><thead><tr><th>進捗</th><th>受付No.</th><th>予約時刻</th><th>受付時刻</th><th>患者No.</th><th>患者氏名</th><th>業務 / 設備</th><th>診療科</th><th>診察医</th><th>次の操作</th></tr></thead>
              <tbody><template v-for="row in rows" :key="row.key">
                <tr :data-row="row.key"><td><span :class="['outpatient-status', row.status]">{{ labels[row.status] }}</span></td><td>{{ row.reception_number || '—' }}</td><td>{{ time(row.scheduled_at) }}</td><td>{{ time(row.received_at) }}</td><td>{{ row.patient_number }}</td><td class="patient-name">{{ row.patient_name }}</td>
                  <td><template v-if="row.kind === 'consultation'"><button v-if="row.equipment.length" type="button" class="outpatient-toggle" :aria-expanded="expanded.has(row.key)" :aria-label="`${row.patient_name}の設備行`" @click="toggle(row)">{{ expanded.has(row.key) ? '▾' : '▸' }}</button>診察<small v-if="row.equipment.length" class="equipment-summary">設備 {{ row.equipment.filter(item => item.status === 'completed').length }}/{{ row.equipment.length }}件完了</small></template><template v-else>{{ row.equipment[0]?.name || '設備' }}（検査のみ）</template></td>
                  <td>{{ row.department_name }}</td><td>{{ row.kind === 'equipment' ? '—' : row.doctor_name || '未定' }}</td><td class="outpatient-action"><button v-if="row.next_action" class="btn btn-primary" :disabled="busy || stale" @click="advance(row, row.next_action)">{{ actions[row.next_action] }}</button><button v-else-if="row.kind === 'equipment' && row.equipment[0]?.next_action" class="btn btn-primary" :disabled="busy || stale" @click="advance(row, 'complete', row.equipment[0].id)">実施</button></td>
                </tr>
                <template v-if="row.kind === 'consultation' && expanded.has(row.key)"><tr v-for="item in row.equipment" :key="item.key" class="outpatient-child" :data-equipment="item.key"><td>{{ equipmentStatus(item) }}</td><td>{{ row.reception_number || '—' }}</td><td>{{ time(item.scheduled_at) }}</td><td>{{ time(row.received_at) }}</td><td>{{ row.patient_number }}</td><td>{{ row.patient_name }}</td><td class="equipment-name">{{ item.name }}</td><td>{{ row.department_name }}</td><td>—</td><td class="outpatient-action"><button v-if="item.next_action" class="btn btn-primary" :disabled="busy || stale" @click="advance(row, item.next_action, item.id)">{{ actions[item.next_action] }}</button></td></tr></template>
              </template></tbody></table>
            <p v-if="!rows.length && !busy" class="search-message">{{ failed ? '取得できませんでした。再検索してください。' : '条件に一致する外来患者はいません。' }}</p>
          </div>
          <footer ref="summary" class="outpatient-foot" tabindex="-1"><span>{{ rows.length }}件（診察・検査のみの単位）</span><span>更新後の検索条件の再適用は「検索」</span></footer>
        </section>
      </main>
    </div>
  </div>
  <OutpatientWorkflowDialog v-if="activeWorkflow === 'patient-search'" mode="受付">
    <PatientSearchWorkspace modal mode="reception" @selected="openReception" @cancelled="closeWorkflow" />
  </OutpatientWorkflowDialog>
  <OutpatientWorkflowDialog v-if="activeWorkflow === 'reception'" mode="受付">
    <ReceptionWorkspace modal :patient-id="selectedPatientId" @completed="completeReception" @cancelled="closeWorkflow" />
  </OutpatientWorkflowDialog>
</template>

<style scoped>
.outpatient-field{display:flex;align-items:center;gap:8px}
.outpatient-app{height:100dvh;display:flex;flex-direction:column}.outpatient-head{height:54px;flex-shrink:0;display:flex;gap:24px;align-items:center;background:#e2e6ea;border-bottom:1px solid #adb5bd;padding:0 18px}.outpatient-head strong{font-size:15px}.outpatient-head h1{font-size:18px;margin:0;padding-left:24px;border-left:1px solid #adb5bd}.outpatient-layout{display:grid;grid-template-columns:180px minmax(0,1fr);flex:1;min-height:0}.outpatient-nav{background:#f8f9fa;border-right:1px solid #adb5bd;padding:16px 10px;display:flex;flex-direction:column;gap:6px}.nav-group{font-size:11px;color:#59636e;padding:0 8px}.outpatient-nav a,.outpatient-nav button{display:flex;align-items:center;gap:8px;min-height:42px;padding:8px;border:1px solid transparent;border-radius:3px;text-decoration:none;background:transparent;color:#495057;white-space:nowrap;text-align:left}.outpatient-nav a{background:#e2e8ef;border-color:#bcc7d2;box-shadow:inset 3px 0 #45647f;font-weight:600}.outpatient-nav button:disabled{cursor:not-allowed}.outpatient-nav small{font-size:9px;margin-left:auto}.outpatient-nav button span,.outpatient-nav a span{font-size:19px}.outpatient-admin{margin-top:auto;border-top:1px solid #ced4da;padding-top:16px}.outpatient-admin button{width:100%}.outpatient-main{min-width:0;min-height:0;padding:16px;display:flex;flex-direction:column;gap:12px}.outpatient-conditions{background:white;border:1px solid #adb5bd;padding:12px 14px}.outpatient-conditions fieldset{padding:0;margin:0;border:0}.outpatient-filters{display:flex;align-items:center;flex-wrap:wrap;gap:12px 22px}.outpatient-filters label{display:flex;align-items:center;gap:8px}.outpatient-filters input,.outpatient-filters select{height:34px;border:1px solid #adb5bd;padding:4px 8px;background:white}.outpatient-filters select{min-width:130px}.outpatient-filters button{margin-left:auto}.outpatient-progress{border-top:1px solid #dee2e6;margin-top:12px;padding-top:10px;display:flex;flex-wrap:wrap;gap:8px;align-items:center}.outpatient-progress label{display:flex;gap:6px;align-items:center;padding:4px 8px;border:1px solid #ced4da;border-radius:2px;background:#f8f9fa}.outpatient-progress input{accent-color:#45647f}.outpatient-results{flex:1;min-height:0;display:flex;flex-direction:column;border:1px solid #adb5bd;background:white}.outpatient-results-head{display:flex;justify-content:space-between;align-items:center;background:#e9ecef;padding:8px 12px;border-bottom:1px solid #adb5bd}.outpatient-results-head h2{font-size:14px;margin:0}.outpatient-results-head span{font-size:12px}.outpatient-scroll{overflow:auto;flex:1;min-height:150px}.outpatient-scroll table{border-spacing:0;width:100%;min-width:1140px;font-size:13px}.outpatient-scroll th,.outpatient-scroll td{padding:8px 9px;text-align:left;border-bottom:1px solid #dce1e5;white-space:nowrap;font-variant-numeric:tabular-nums}.outpatient-scroll th{position:sticky;top:0;background:#f4f6f8;z-index:2}.outpatient-action{position:sticky;right:0;background:white;z-index:1;box-shadow:-1px 0 #dce1e5}.outpatient-scroll th:last-child{right:0;z-index:3}.outpatient-child td{background:#f3f6f9}.equipment-name{padding-left:26px!important;border-left:3px solid #bcc7d2}.equipment-summary{display:block;color:#59636e;font-size:11px}.outpatient-toggle{border:0;background:transparent;color:#334e68;padding:3px 5px}.patient-name{font-weight:600}.outpatient-status{display:inline-block;min-width:66px;padding:2px 7px;background:#f3f4f5;border:1px solid #bdc5cd;border-radius:2px;font-size:12px}.consulting{background:#faf5e7;color:#665014}.billing_wait{background:#eff5f0;color:#39553e}.outpatient-foot{display:flex;justify-content:space-between;gap:12px;padding:8px 12px;border-top:1px solid #adb5bd;font-size:12px}.outpatient-message{margin:0;padding:8px 12px;border-left:3px solid #26713c;background:white}.outpatient-message.error{border-color:#b02a37;color:#b02a37}.btn{font-size:13px;min-width:88px}.outpatient-app :focus-visible{outline:2px solid #0b5ed7;outline-offset:2px}@media(max-width:800px){.outpatient-layout{grid-template-columns:164px minmax(0,1fr)}.outpatient-main{padding:10px}.outpatient-head{gap:12px}.outpatient-head h1{padding-left:12px}}
.outpatient-nav-action{width:100%;border-color:#7895ac!important;background:#edf4f9!important;color:#244864!important;font-weight:600}
</style>
