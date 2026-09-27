<script setup>
// 外来一覧から開くマスタ設定の作業領域。左の選択状態と右の一覧状態を保持し、各マスタのAPIを呼び分ける。
import { computed, onMounted, ref } from 'vue'
import { searchPatients } from '../../patients/api.js'
import PatientForm from '../../patients/components/PatientForm.vue'
import { searchDepartments } from '../departments/api.js'
import DepartmentForm from '../departments/components/DepartmentForm.vue'
import { searchOccupations } from '../occupations/api.js'
import OccupationForm from '../occupations/components/OccupationForm.vue'
import UserMasterPane from '../users/components/UserMasterPane.vue'
import ReservationSlotMasterPane from '../reservation-slots/components/ReservationSlotMasterPane.vue'

const emit = defineEmits(['cancelled'])
const master = ref('patient'), keyword = ref(''), active = ref(''), rows = ref([]), selectedId = ref(null), busy = ref(false), message = ref('')
const editingId = ref(null), formOpen = ref(false)
const reservationSlotPane = ref(null), reservationSlotDirty = ref(false), pendingMaster = ref(null)
const definitions = {
  patient: { label: '患者マスタ', group: '患者情報', placeholder: '患者番号・氏名・カナ氏名', columns: [['patient_number','患者番号'], ['name','氏名'], ['kana','カナ氏名'], ['birth_date','生年月日'], ['sex','性別']] },
  department: { label: '診療科マスタ', group: '業務マスタ', placeholder: '診療科名・カナ名', columns: [['id','ID'], ['name','診療科名'], ['kana_name','カナ名'], ['abbreviation','略名'], ['display_order','表示順'], ['active','利用状態']] },
  occupation: { label: '職種マスタ', group: '業務マスタ', placeholder: '職種名', columns: [['id','ID'], ['name','職種名'], ['display_order','表示順'], ['active','利用状態']] },
  user: { label: 'ユーザーマスタ', group: '利用者・権限', placeholder: '', columns: [] },
  reservationSlot: { label: '予約枠マスタ', group: '業務マスタ', placeholder: '', columns: [] },
}
const definition = computed(() => definitions[master.value])
const formComponent = computed(() => ({ patient: PatientForm, department: DepartmentForm, occupation: OccupationForm })[master.value])
const formIdProp = computed(() => ({ patient: 'patient-id', department: 'department-id', occupation: 'occupation-id' })[master.value])
const normalizedRows = computed(() => rows.value.map(row => master.value === 'patient' ? ({ ...row, name: `${row.last_name} ${row.first_name}`, kana: `${row.last_name_kana} ${row.first_name_kana}`, sex: ({ male: '男性', female: '女性', other: 'その他' })[row.sex] || '—' }) : ({ ...row, active: row.active ? '利用中' : '停止中' })))
// 選択先の状態を初期化し、検索可能なマスタなら新しい条件で一覧を取得する。
function applyMaster(next) {
  pendingMaster.value = null
  master.value = next; keyword.value = ''; active.value = ''; selectedId.value = null; editingId.value = null; formOpen.value = false
  if (next !== 'user' && next !== 'reservationSlot') load()
}
// マスタ切替の窓口。予約枠フォームが未保存なら、子の確認が終わるまで切替を保留する。
async function select(next) {
  if (next === master.value) return
  // 予約枠フォームだけは、設計v0.2どおり左ナビ切替でも未保存の破棄確認を通す。
  if (master.value === 'reservationSlot' && reservationSlotDirty.value) {
    pendingMaster.value = next
    if (!await reservationSlotPane.value?.requestLeave()) return
  }
  applyMaster(next)
}
// 予約枠フォームの破棄確認が完了した後、保留していた切替先を反映する。
function completePendingMaster() { if (pendingMaster.value) applyMaster(pendingMaster.value) }
// 選択中マスタに応じたAPIを呼び、検索結果と通信状態を更新する。
async function load() { busy.value = true; message.value = ''; selectedId.value = null; try { rows.value = master.value === 'patient' ? await searchPatients({ patientNumber: /^\d+$/.test(keyword.value) ? keyword.value : '', name: /^\d+$/.test(keyword.value) ? '' : keyword.value }) : master.value === 'department' ? await searchDepartments({ keyword: keyword.value, active: active.value }) : await searchOccupations({ keyword: keyword.value, active: active.value }) } catch (error) { rows.value = []; message.value = error.message || '検索に失敗しました。' } finally { busy.value = false } }
// 選択中マスタのフォームを新規または既存IDで表示する。
function openForm(id = null) { editingId.value = id; formOpen.value = true }
// 保存結果を受けて一覧を再検索し、更新したレコードを選び直す。
async function closeForm(saved) {
  editingId.value = null
  formOpen.value = false
  const savedRecord = saved?.patient || saved?.department || saved?.occupation || saved
  if (savedRecord?.id) {
    await load()
    selectedId.value = savedRecord.id
    message.value = `${definition.value.label}を保存しました。検索結果を更新しました。`
  }
}
onMounted(load)
</script>

<template>
  <section class="master-settings">
    <!-- 左ナビでマスタを選択し、selectが未保存フォームの切替確認を行う。 -->
    <nav class="master-settings__nav" aria-label="設定するマスタ"><strong>マスタ設定</strong><span>患者情報</span><button :class="{ active: master === 'patient' }" @click="select('patient')">患者マスタ</button><span>業務マスタ</span><button :class="{ active: master === 'department' }" @click="select('department')">診療科マスタ</button><button :class="{ active: master === 'occupation' }" @click="select('occupation')">職種マスタ</button><button :class="{ active: master === 'reservationSlot' }" @click="select('reservationSlot')">予約枠マスタ</button><span>利用者・権限</span><button :class="{ active: master === 'user' }" @click="select('user')">ユーザーマスタ</button></nav>
    <main class="master-settings__main">
      <header v-if="master !== 'user' && master !== 'reservationSlot'" class="master-settings__title"><h1>{{ definition.label }}</h1><span>{{ definition.label.replace('マスタ', '') }}を検索し、登録・編集します。</span></header>
      <!-- ユーザー・予約枠は専用ペイン、それ以外は共通検索一覧と編集フォームを使う。 -->
      <UserMasterPane v-if="master === 'user'" @cancelled="emit('cancelled')" />
      <ReservationSlotMasterPane v-else-if="master === 'reservationSlot'" ref="reservationSlotPane" @cancelled="emit('cancelled')" @dirty-change="reservationSlotDirty = $event" @form-closed="completePendingMaster" />
      <template v-else-if="!formOpen">
        <form class="master-settings__search" @submit.prevent="load"><label>検索条件<input v-model="keyword" :placeholder="definition.placeholder" autocomplete="off"></label><label v-if="master !== 'patient'">利用状態<select v-model="active"><option value="">すべて</option><option value="true">利用中</option><option value="false">停止中</option></select></label><button class="btn btn-secondary" :disabled="busy">検索</button></form>
        <section class="master-settings__results" aria-live="polite"><header><strong>検索結果</strong><span>{{ normalizedRows.length }}件</span></header><div class="master-settings__grid"><table><thead><tr><th v-for="column in definition.columns" :key="column[0]" scope="col">{{ column[1] }}</th></tr></thead><tbody><tr v-for="row in normalizedRows" :key="row.id" :class="{ selected: selectedId === row.id }" @click="selectedId = row.id"><td v-for="column in definition.columns" :key="column[0]">{{ row[column[0]] ?? '—' }}</td></tr></tbody></table><p v-if="!busy && !normalizedRows.length && !message" class="master-settings__message">該当する{{ definition.label }}はありません。</p><p v-if="message" class="master-settings__message">{{ message }}</p></div></section>
        <footer><span>行を選択してから「編集」を押します。</span><div><button class="btn btn-secondary" type="button" @click="openForm()">新規</button><button class="btn btn-secondary" type="button" :disabled="!selectedId" @click="openForm(selectedId)">編集</button><button class="btn btn-secondary" type="button" @click="emit('cancelled')">閉じる</button></div></footer>
      </template>
      <component :is="formComponent" v-else embedded :[formIdProp]="editingId" @close="closeForm" />
    </main>
  </section>
</template>

<style scoped>
.master-settings{display:grid;grid-template-columns:220px minmax(0,1fr);flex:1;min-height:0}.master-settings__nav{display:flex;flex-direction:column;gap:6px;padding:16px 10px;background:#f8f9fa;border-right:1px solid #adb5bd}.master-settings__nav span{margin:10px 8px 0;color:#59636e;font-size:11px}.master-settings__nav button{text-align:left;min-height:40px;border:1px solid transparent;background:transparent;padding:8px;color:#495057}.master-settings__nav button.active{background:#e2e8ef;border-color:#bcc7d2;box-shadow:inset 3px 0 #45647f;font-weight:700}.master-settings__nav small{float:right}.master-settings__main{min-height:0;padding:18px;display:flex;flex-direction:column;gap:12px}.master-settings__title{display:flex;align-items:baseline;justify-content:space-between;gap:12px}.master-settings__main h1{margin:0;font-size:18px}.master-settings__title span{color:#59636e;font-size:12px}.master-settings__search{display:flex;gap:12px;align-items:end;padding:12px;background:white;border:1px solid #adb5bd}.master-settings__search label{display:grid;gap:4px}.master-settings__search input,.master-settings__search select{height:34px;min-width:220px}.master-settings__results{min-height:0;flex:1;display:flex;flex-direction:column;border:1px solid #adb5bd;background:white}.master-settings__results header,footer{display:flex;justify-content:space-between;padding:9px 12px;background:#e9ecef;border-bottom:1px solid #adb5bd}.master-settings__grid{overflow:auto;flex:1}.master-settings table{border-collapse:collapse;width:100%}.master-settings th,.master-settings td{padding:9px;border-bottom:1px solid #dce1e5;text-align:left}.master-settings th{position:sticky;top:0;background:#f4f6f8}.master-settings tr{cursor:pointer}.master-settings tr.selected{background:#e7f1fb}.master-settings__message{margin:0;padding:14px}.master-settings footer{border-top:1px solid #adb5bd;border-bottom:0;margin-top:auto;background:#f1f3f5}.master-settings footer div{display:flex;gap:8px}.master-settings footer button:last-child{margin-left:8px}@media(max-width:760px){.master-settings{grid-template-columns:155px minmax(0,1fr)}.master-settings__main{padding:12px}.master-settings__title{align-items:flex-start;flex-direction:column}.master-settings__search{align-items:stretch;flex-direction:column}.master-settings__search input,.master-settings__search select{min-width:0;width:100%}}
</style>
