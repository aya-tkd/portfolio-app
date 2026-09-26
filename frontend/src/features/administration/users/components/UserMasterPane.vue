<script setup>
// MasterSettingsWorkspace の右ペイン。ユーザーの検索一覧と登録・編集を同じ画面内で切り替え、保存後は一覧へ戻す。
import { onMounted, reactive, ref } from 'vue'
import { searchDepartments } from '../../departments/api.js'
import { searchOccupations } from '../../occupations/api.js'
import { searchUsers } from '../api.js'
import UserForm from './UserForm.vue'

const emit = defineEmits(['cancelled'])
const rows = ref([])
const departments = ref([])
const occupations = ref([])
const selectedId = ref(null)
const editing = ref(false)
const busy = ref(false)
const message = ref('')
const conditions = reactive({ userId: '', name: '', departmentId: '', occupationId: '' })
const editingId = ref(null)

// 現在の4条件で検索し、ユーザー一覧と選択状態を更新する。
async function load() {
  busy.value = true
  message.value = ''
  try { rows.value = await searchUsers(conditions); selectedId.value = null } catch (error) { rows.value = []; message.value = error.message || '検索に失敗しました。' } finally { busy.value = false }
}

// 一覧から編集対象IDを渡すか、新規用にnullを渡してフォームへ切り替える。
function open(id = null) {
  message.value = ''
  editingId.value = id
  editing.value = true
}
// 保存結果を受けて一覧へ戻り、同じ行を検索結果から選び直す。
async function closeForm(saved) {
  editing.value = false
  editingId.value = null
  if (saved?.id) {
    await load()
    selectedId.value = rows.value.some(row => row.id === saved.id) ? saved.id : null
    if (!message.value) message.value = '保存しました。検索結果を更新しました。'
  }
}

// フォームの診療科・職種select用に、有効な関連マスタを並行取得する。
async function loadOptions() {
  try { ;[departments.value, occupations.value] = await Promise.all([searchDepartments({ active: 'true' }), searchOccupations({ active: 'true' })]) } catch (error) { message.value = error.message || '診療科・職種の選択肢を取得できませんでした。' }
}
onMounted(async () => { await load(); await loadOptions() })
</script>

<template>
  <section class="user-pane">
    <header class="user-pane__title"><h1>ユーザーマスタ</h1><span>スタッフ基本情報を検索・登録・編集します。</span></header>
    <template v-if="!editing">
      <!-- 検索条件・検索結果・行操作を表示し、選択行からフォームへ進む。 -->
      <form class="user-pane__search" @submit.prevent="load">
        <label>ユーザーID<input v-model="conditions.userId" inputmode="numeric" autocomplete="off"></label><label>氏名・カナ氏名<input v-model="conditions.name" autocomplete="off"></label><label>診療科<select v-model="conditions.departmentId"><option value="">すべて</option><option v-for="department in departments" :key="department.id" :value="department.id">{{ department.name }}</option></select></label><label>職種<select v-model="conditions.occupationId"><option value="">すべて</option><option v-for="occupation in occupations" :key="occupation.id" :value="occupation.id">{{ occupation.name }}</option></select></label><button class="btn btn-secondary" :disabled="busy">検索</button>
      </form>
      <section class="user-pane__results" aria-live="polite"><header><strong>検索結果</strong><span>{{ rows.length }}件</span></header><div class="user-pane__grid"><table><thead><tr><th>ユーザーID</th><th>氏名</th><th>カナ氏名</th><th>診療科</th><th>職種</th><th>利用状態</th></tr></thead><tbody><tr v-for="row in rows" :key="row.id" :class="{ selected: selectedId === row.id }" @click="selectedId = row.id"><td>{{ row.id }}</td><td>{{ row.last_name }} {{ row.first_name }}</td><td>{{ row.last_name_kana }} {{ row.first_name_kana }}</td><td>{{ row.department_name || '未設定' }}</td><td>{{ row.occupation_name || '未設定' }}</td><td>{{ row.active ? '利用中' : '停止中' }}</td></tr></tbody></table><p v-if="!busy && !rows.length && !message" class="user-pane__message">該当するユーザーはいません。</p><p v-if="message" class="user-pane__message">{{ message }}</p></div></section>
      <footer class="user-pane__footer"><span>行を選択してから、「編集」を押します。</span><div><button type="button" class="btn btn-secondary" @click="open()">新規</button><button type="button" class="btn btn-secondary" :disabled="!selectedId" @click="open(selectedId)">編集</button><button type="button" class="btn btn-secondary user-pane__close" @click="emit('cancelled')">閉じる</button></div></footer>
    </template>
    <!-- 編集中は一覧をフォームへ置き換え、closeイベントで親へ保存結果を返す。 -->
    <UserForm v-else :user-id="editingId" :departments="departments" :occupations="occupations" @close="closeForm" />
  </section>
</template>

<style scoped>
.user-pane{min-height:0;flex:1;display:flex;flex-direction:column;gap:12px}.user-pane__title{display:flex;align-items:baseline;justify-content:space-between;gap:12px}.user-pane__title h1{margin:0;font-size:18px}.user-pane__title span{color:#59636e;font-size:12px}.user-pane__search{display:flex;gap:12px;align-items:end;flex-wrap:wrap;padding:12px;background:#fff;border:1px solid #adb5bd}.user-pane__search label{display:grid;gap:4px}.user-pane__search input,.user-pane__search select{height:34px;min-width:150px}.user-pane__results{min-height:0;flex:1;display:flex;flex-direction:column;border:1px solid #adb5bd;background:#fff}.user-pane__results header{display:flex;justify-content:space-between;padding:9px 12px;background:#e9ecef;border-bottom:1px solid #adb5bd}.user-pane__grid{overflow:auto;flex:1}.user-pane table{border-collapse:collapse;width:100%;min-width:760px}.user-pane th,.user-pane td{padding:9px;border-bottom:1px solid #dce1e5;text-align:left}.user-pane th{position:sticky;top:0;background:#f4f6f8}.user-pane tr{cursor:pointer}.user-pane tr.selected{background:#e7f1fb}.user-pane__message{margin:0;padding:14px}.user-pane__footer{display:flex;justify-content:space-between;align-items:center;padding:9px 12px;border:1px solid #adb5bd;background:#f1f3f5}.user-pane__footer div{display:flex;gap:8px}.user-pane__close{margin-left:8px}@media(max-width:760px){.user-pane__title{align-items:flex-start;flex-direction:column}.user-pane__search{align-items:stretch;flex-direction:column}.user-pane__search input,.user-pane__search select{min-width:0;width:100%}.user-pane__footer{align-items:flex-start;gap:8px;flex-direction:column}}
</style>
