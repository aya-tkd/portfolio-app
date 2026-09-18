<script setup>
// 患者検索の条件入力・一覧選択・既存登録/編集ダイアログ起動を一画面で管理するコンポーネント。
// App.vueが /patients で呼び出し、searchPatientsから受け取る患者配列を表示する。保存後も条件を保持して再検索する。
import { computed, nextTick, onMounted, ref } from 'vue'
import { ApiError } from '../../../shared/api/http.js'
import { searchPatients } from '../api.js'
import PatientForm from './PatientForm.vue'

const props = defineProps({
  modal: { type: Boolean, default: false },
  // 呼び出し元により画面下部の操作を変える。患者マスタからの利用時に受付導線を固定しない。
  mode: { type: String, default: 'management' },
})
const emit = defineEmits(['selected', 'cancelled'])

const patientNumber = ref('')
const name = ref('')
const patients = ref([])
const selectedId = ref(null)
const loading = ref(false)
const message = ref('')
const active = ref(false)
const editingId = ref(null)
const opener = ref(null)
const resultHeading = ref(null)
const hasSelection = computed(() => selectedId.value !== null)

function select(patient) {
  selectedId.value = patient.id
}

async function search(preferredId = null, focusResult = false) {
  if (loading.value) return
  loading.value = true
  message.value = ''
  try {
    const result = await searchPatients({ patientNumber: patientNumber.value, name: name.value })
    patients.value = result
    const preferred = preferredId ?? selectedId.value
    selectedId.value = result.some(patient => patient.id === preferred) ? preferred : null
    if (!result.length) message.value = '該当する患者はいません。'
  } catch (error) {
    patients.value = []
    selectedId.value = null
    message.value = error instanceof ApiError ? error.message : '検索に失敗しました。通信状態を確認してから再実行してください。'
  } finally {
    loading.value = false
    await nextTick()
    if (focusResult) resultHeading.value?.focus()
  }
}

function submitSearch() {
  return search(null, true)
}

function open(patientId, event) {
  opener.value = event?.currentTarget || document.getElementById('patient-search-button')
  editingId.value = patientId
  active.value = true
}

async function closeForm(saved) {
  active.value = false
  if (saved) {
    message.value = `患者番号 ${saved.patient_number} を保存しました。検索結果を更新しました。`
    await search(saved.id, true)
  }
  await nextTick()
  opener.value?.focus()
}

function closeWorkspace() {
  // この画面は患者業務の入口から開かれる想定のため、閉じると既存の患者管理入口へ戻す。
  if (props.modal) emit('cancelled')
  else window.location.assign('/')
}

function openReception() {
  if (!selectedId.value) return
  if (props.mode === 'reception') emit('selected', patients.value.find(patient => patient.id === selectedId.value))
  else window.location.assign(`/receptions/new?patient_id=${selectedId.value}`)
}

onMounted(() => search())
</script>

<template>
  <div :class="{ 'workflow-overlay': modal }">
  <header class="app-head"><strong>外来業務</strong><span>患者検索</span></header>
  <main class="workspace patient-search">
    <h1>患者検索</h1>

    <form class="search-panel" @submit.prevent="submitSearch">
      <h2>検索条件</h2>
      <div class="search-fields">
        <label for="patient-number">患者番号</label>
        <input id="patient-number" v-model="patientNumber" class="form-control" maxlength="100" autocomplete="off">
        <label for="patient-name">氏名・カナ</label>
        <input id="patient-name" v-model="name" class="form-control" maxlength="200" autocomplete="off">
      </div>
      <div class="search-actions"><button id="patient-search-button" type="submit" class="btn btn-secondary" :disabled="loading">検索</button></div>
    </form>

    <section class="result-panel" aria-labelledby="patient-search-result">
      <h2 id="patient-search-result" ref="resultHeading" tabindex="-1">検索結果</h2>
      <p v-if="loading" role="status">検索中です。</p>
      <p v-else-if="message" class="search-message" :class="{ 'is-empty': !patients.length }" role="status">{{ message }}</p>
      <div v-else class="result-table-wrap">
        <table>
          <thead><tr><th scope="col">選択</th><th scope="col">患者番号</th><th scope="col">氏名</th><th scope="col">カナ氏名</th><th scope="col">生年月日</th><th scope="col">性別</th></tr></thead>
          <tbody>
            <tr v-for="patient in patients" :key="patient.id" :class="{ selected: selectedId === patient.id }" @click="select(patient)">
              <td><input :id="`patient-${patient.id}`" v-model="selectedId" type="radio" name="selected-patient" :value="patient.id" :aria-label="`患者番号 ${patient.patient_number} を選択`"></td>
              <td>{{ patient.patient_number }}</td>
              <td>{{ patient.last_name }} {{ patient.first_name }} <small v-if="patient.has_today_reservation" class="reservation-flag">本日予約あり</small></td>
              <td>{{ patient.last_name_kana }} {{ patient.first_name_kana }}</td>
              <td>{{ patient.birth_date || '―' }}</td>
              <td>{{ { male: '男性', female: '女性', other: 'その他' }[patient.sex] || '―' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <footer class="screen-foot">
      <div v-if="mode !== 'reception'" class="buttons">
        <button type="button" class="btn btn-secondary" @click="open(null, $event)">新規</button>
        <button type="button" class="btn btn-secondary" :disabled="!hasSelection" @click="open(selectedId, $event)">編集</button>
      </div>
      <div v-else></div>
      <div class="buttons">
        <button v-if="mode === 'reception'" type="button" class="btn btn-primary" :disabled="!hasSelection" @click="openReception">受付</button>
        <button type="button" class="btn btn-secondary" @click="closeWorkspace">閉じる</button>
      </div>
    </footer>
  </main>
  <PatientForm v-if="active" :patient-id="editingId" @close="closeForm" />
  </div>
</template>
