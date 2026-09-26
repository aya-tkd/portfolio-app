<script setup>
// MasterSettingsWorkspaceの右ペイン。予約枠の検索条件・選択・ページングを管理し、フォーム保存後に同じ条件で再取得する。
import { computed, onMounted, reactive, ref } from 'vue'
import { loadReservationSlotOptions, searchReservationSlots } from '../api.js'
import ReservationSlotForm from './ReservationSlotForm.vue'

const emit = defineEmits(['cancelled', 'dirty-change', 'form-closed'])
const rows = ref([]), departments = ref([]), doctors = ref([]), selectedId = ref(null), editingId = ref(null), busy = ref(false), optionBusy = ref(false), editing = ref(false), message = ref(''), page = ref(1), total = ref(0)
const conditions = reactive({ keyword: '', slotGroup: '', defaultDepartmentId: '', active: '' })
const formRef = ref()
const perPage = 50
let loadSequence = 0
const pageCount = computed(() => Math.max(1, Math.ceil(total.value / perPage)))
const groupLabel = group => ({ consultation: '診察', equipment: '設備' })[group] || group
const activeLabel = active => active ? '有効' : '無効'
const timeLabel = row => `${row.start_time}〜${row.end_time}／${row.interval_minutes}分`
const periodLabel = row => `${row.valid_from}〜${row.valid_to}`
const weekdayLabel = days => Array(days).map(day => ({ 1: '月', 2: '火', 3: '水', 4: '木', 5: '金', 6: '土', 7: '日' }[day] || '')).filter(Boolean).join('・')

// 検索条件とページをAPIへ渡し、検索結果・選択状態・画面メッセージを更新する。
async function load({ resetPage = false, preserveId = null } = {}) {
  if (resetPage) page.value = 1
  // 初期検索・保存後再検索など複数の非同期応答が逆順に返っても、古い結果で一覧を上書きしない。
  const sequence = ++loadSequence
  busy.value = true; message.value = ''
  try {
    const result = await searchReservationSlots({ ...conditions, page: page.value, perPage })
    if (sequence !== loadSequence) return
    rows.value = result.items; total.value = result.total
    selectedId.value = rows.value.some(row => row.id === preserveId) ? preserveId : null
    if (preserveId && !selectedId.value) message.value = `枠ID ${preserveId} を保存しました。現在の検索条件またはページには表示されません。`
  } catch (error) {
    if (sequence !== loadSequence) return
    rows.value = []; total.value = 0; selectedId.value = null; message.value = error.message || '検索に失敗しました。'
  } finally { if (sequence === loadSequence) busy.value = false }
}
// フォームで使う診療科・医師候補を親画面の初期表示時にまとめて取得する。
async function loadOptions() {
  optionBusy.value = true
  try { const options = await loadReservationSlotOptions(); departments.value = options.departments; doctors.value = options.doctor_users }
  catch (error) { message.value = error.message || '診療科・医師の選択肢を取得できませんでした。' }
  finally { optionBusy.value = false }
}
// 新規または選択行の編集フォームへ切り替える。
function open(id = null) { if (optionBusy.value) return; editingId.value = id; editing.value = true; message.value = '' }
// 保存後は検索結果を再取得し、保存行が現在の条件内なら選択状態に戻す。
async function closeForm(saved) {
  editing.value = false; editingId.value = null
  if (saved?.id) { await load({ resetPage: true, preserveId: saved.id }); if (!message.value) message.value = '保存しました。検索結果を更新しました。' }
  else emit('form-closed')
}
// 件数と現在ページの範囲内だけページ移動を許可する。
async function changePage(next) { if (next < 1 || next > pageCount.value || busy.value) return; page.value = next; await load() }

// 左ナビ切替時の未保存保護。フォームが破棄確認を出した場合は切替を保留する。
async function requestLeave() { if (!editing.value) return true; return formRef.value?.close() || false }
// フォームの未保存状態を左ナビ側へ伝え、切替前の確認に使う。
function setDirty(value) { emit('dirty-change', value) }
onMounted(async () => { await Promise.all([loadOptions(), load()]) })
defineExpose({ requestLeave })
</script>

<template>
  <section class="reservation-slot-pane">
    <header class="reservation-slot-pane__title"><h1>予約枠マスタ</h1><span>予約枠を検索し、登録・編集します。</span></header>
    <template v-if="!editing">
      <!-- 検索条件はこのペインで保持し、検索ボタンとEnterキーで一覧を更新する。 -->
      <form class="reservation-slot-pane__search" @submit.prevent="load({ resetPage: true })">
        <label>枠名<input v-model="conditions.keyword" autocomplete="off"></label><label>枠グループ<select v-model="conditions.slotGroup"><option value="">すべて</option><option value="consultation">診察</option><option value="equipment">設備</option></select></label><label>初期診療科<select v-model="conditions.defaultDepartmentId"><option value="">すべて</option><option v-for="department in departments" :key="department.id" :value="department.id">{{ department.name }}</option></select></label><label>利用状態<select v-model="conditions.active"><option value="">すべて</option><option value="true">有効</option><option value="false">無効</option></select></label><button class="btn btn-secondary" :disabled="busy">検索</button>
      </form>
      <!-- 結果行の選択が編集対象を決める。表本体だけをスクロールし、ページ操作は下部に固定する。 -->
      <section class="reservation-slot-pane__results" aria-live="polite"><header><strong>検索結果</strong><span>{{ total }}件</span><small>診療科・医師は予約時の初期値です。</small></header><div class="reservation-slot-pane__grid"><table><thead><tr><th>ID</th><th>枠名</th><th>グループ</th><th>曜日 / 有効期間</th><th>時間 / 間隔</th><th>各枠定員</th><th>初期診療科 / 医師</th><th>状態</th></tr></thead><tbody><tr v-for="row in rows" :key="row.id" :class="{ selected: selectedId === row.id }" tabindex="0" @click="selectedId = row.id" @keydown.enter.prevent="selectedId = row.id" @keydown.space.prevent="selectedId = row.id"><td>{{ row.id }}</td><td>{{ row.name }}</td><td>{{ groupLabel(row.slot_group) }}</td><td>{{ weekdayLabel(row.weekdays) }}<small>{{ periodLabel(row) }}</small></td><td>{{ timeLabel(row) }}</td><td>{{ row.capacity }}人</td><td>{{ row.default_department_name || '—' }}<small>{{ row.default_doctor_name || '—' }}</small></td><td>{{ activeLabel(row.active) }}</td></tr></tbody></table><p v-if="!busy && !rows.length && !message" class="reservation-slot-pane__message">該当する予約枠はありません。</p><p v-if="message" class="reservation-slot-pane__message">{{ message }}</p></div></section>
      <!-- ページ移動・新規・選択行の編集と、親画面へ戻る操作をまとめる。 -->
      <footer class="reservation-slot-pane__footer"><span>{{ page }} / {{ pageCount }} ページ（{{ perPage }}件ずつ）</span><div><button type="button" class="btn btn-secondary" :disabled="page <= 1 || busy" @click="changePage(page - 1)">前へ</button><button type="button" class="btn btn-secondary" :disabled="page >= pageCount || busy" @click="changePage(page + 1)">次へ</button><button type="button" class="btn btn-secondary reservation-slot-pane__new" :disabled="optionBusy" @click="open()">新規</button><button type="button" class="btn btn-secondary" :disabled="!selectedId || optionBusy" @click="open(selectedId)">編集</button><button type="button" class="btn btn-secondary reservation-slot-pane__close" @click="emit('cancelled')">閉じる</button></div></footer>
    </template>
    <ReservationSlotForm v-else ref="formRef" :slot-id="editingId" :departments="departments" :doctors="doctors" @close="closeForm" @dirty-change="setDirty" />
  </section>
</template>

<style scoped>
.reservation-slot-pane{min-height:0;flex:1;display:flex;flex-direction:column;gap:12px}.reservation-slot-pane__title{display:flex;align-items:baseline;justify-content:space-between;gap:12px}.reservation-slot-pane__title h1{margin:0;font-size:18px}.reservation-slot-pane__title span{color:#59636e;font-size:12px}.reservation-slot-pane__search{display:grid;grid-template-columns:minmax(180px,2fr) minmax(130px,1fr) minmax(130px,1fr) minmax(120px,1fr) auto;gap:12px;align-items:end;padding:12px;background:#fff;border:1px solid #adb5bd}.reservation-slot-pane__search label{display:grid;gap:4px}.reservation-slot-pane__search input,.reservation-slot-pane__search select{height:34px;min-width:0}.reservation-slot-pane__results{min-height:0;flex:1;display:flex;flex-direction:column;border:1px solid #adb5bd;background:#fff}.reservation-slot-pane__results header{display:flex;gap:8px;align-items:center;padding:9px 12px;background:#e9ecef;border-bottom:1px solid #adb5bd}.reservation-slot-pane__results header small{margin-left:auto;color:#495057}.reservation-slot-pane__grid{overflow:auto;flex:1}.reservation-slot-pane table{border-collapse:collapse;width:100%;min-width:960px}.reservation-slot-pane th,.reservation-slot-pane td{padding:9px;border-bottom:1px solid #dce1e5;text-align:left;vertical-align:top}.reservation-slot-pane th{position:sticky;top:0;background:#f4f6f8}.reservation-slot-pane td small{display:block;margin-top:4px;color:#59636e}.reservation-slot-pane tr{cursor:pointer}.reservation-slot-pane tr.selected{background:#e7f1fb}.reservation-slot-pane__message{margin:0;padding:14px}.reservation-slot-pane__footer{display:flex;justify-content:space-between;align-items:center;padding:9px 12px;border:1px solid #adb5bd;background:#f1f3f5}.reservation-slot-pane__footer div{display:flex;gap:8px}.reservation-slot-pane__new{margin-left:8px}.reservation-slot-pane__close{margin-left:8px}@media(max-width:900px){.reservation-slot-pane__search{grid-template-columns:1fr 1fr}.reservation-slot-pane__title{align-items:flex-start;flex-direction:column}}@media(max-width:650px){.reservation-slot-pane__search{grid-template-columns:1fr}.reservation-slot-pane__footer{align-items:flex-start;gap:8px;flex-direction:column;flex-wrap:wrap}.reservation-slot-pane__footer div{flex-wrap:wrap}}
/* 一覧はモーダルの幅に合わせ、長い名称はセル内で折り返す。横スクロールを常態化させない。 */
.reservation-slot-pane table{table-layout:fixed;min-width:0}.reservation-slot-pane th,.reservation-slot-pane td{overflow-wrap:anywhere}.reservation-slot-pane th{font-size:12px}.reservation-slot-pane th:nth-child(1),.reservation-slot-pane td:nth-child(1){width:4%}.reservation-slot-pane th:nth-child(2),.reservation-slot-pane td:nth-child(2){width:20%}.reservation-slot-pane th:nth-child(3),.reservation-slot-pane td:nth-child(3){width:8%}.reservation-slot-pane th:nth-child(4),.reservation-slot-pane td:nth-child(4){width:18%}.reservation-slot-pane th:nth-child(5),.reservation-slot-pane td:nth-child(5){width:14%}.reservation-slot-pane th:nth-child(6),.reservation-slot-pane td:nth-child(6){width:9%}.reservation-slot-pane th:nth-child(7),.reservation-slot-pane td:nth-child(7){width:20%}.reservation-slot-pane th:nth-child(8),.reservation-slot-pane td:nth-child(8){width:7%}
</style>
