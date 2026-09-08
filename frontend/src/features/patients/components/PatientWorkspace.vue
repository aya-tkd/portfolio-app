<script setup>
// 患者フォームの呼び出し元。子のcloseイベントで保存結果を受け取る。
// 一覧は別Issueのため、内部ID指定と直URLで編集を確認する最小ホスト。
import { ref, onMounted, nextTick } from 'vue'
import PatientForm from './PatientForm.vue'

const active = ref(false), patientId = ref(null), editId = ref(''), notice = ref(''), opener = ref(null)
function open(id, event) {
  if (id && !/^[1-9][0-9]*$/.test(String(id))) { notice.value = '内部IDは正の整数で指定してください。'; return }
  opener.value = event?.currentTarget || document.getElementById('new')
  patientId.value = id || null
  active.value = true
  history.replaceState(null, '', id ? `/patients/${id}/edit` : '/patients/new')
}
async function close(saved) {
  active.value = false
  history.replaceState(null, '', '/')
  if (saved) { editId.value = String(saved.id); notice.value = `患者番号 ${saved.patient_number} を登録しました。` }
  // VueがダイアログをDOMから除去するまで待つ。先にfocusしても背面は操作不可のまま。
  await nextTick()
  opener.value?.focus()
}
onMounted(() => {
  const path = location.pathname
  if (path === '/patients/new') open(null)
  else if (/^\/patients\/[1-9][0-9]*\/edit$/.test(path)) open(path.split('/')[2])
  else if (path !== '/') notice.value = '指定された画面はありません。新規または内部ID指定で開いてください。'
})
</script>

<template>
  <header class="app-head"><strong>外来業務</strong><span>患者管理</span></header>
  <main class="host">
    <h1>患者登録・編集</h1>
    <p class="text-secondary">ローカル学習用・架空データ限定。患者一覧は未実装です。</p>
    <div class="host-toolbar">
      <button id="new" class="btn btn-secondary" @click="open(null, $event)">新規</button>
      <label for="edit-id">内部ID（呼び出し確認用）</label>
      <input id="edit-id" v-model="editId" class="form-control" inputmode="numeric">
      <button class="btn btn-secondary" @click="open(editId || 'invalid', $event)">編集</button>
    </div>
    <p v-if="notice" class="host-notice" role="status">{{ notice }}</p>
  </main>
  <PatientForm v-if="active" :patient-id="patientId" @close="close" />
</template>
