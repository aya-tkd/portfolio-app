<script setup>
// ローカルDBの読み取り画面。ページ状態とスキーマ閲覧を独立して管理する。
// 編集途中のSQLでページ送りを行わず、実行ボタンで新しい検索を開始する。
import { computed, onMounted, ref } from 'vue'
import { request, ApiError } from '../../../shared/api/http.js'
const sql = ref('SELECT * FROM mst_patients ORDER BY id DESC;')
const executedSql = ref(''), busy = ref(false), result = ref(null), error = ref('')
const tables = ref([]), schemaError = ref(''), schema = ref(null), schemaBusy = ref(false), dialog = ref(null)
const categories = [['master', 'マスタ'], ['transaction', 'トランザクション'], ['log', 'ログ'], ['system', 'システム'], ['unclassified', '未分類']]
const groups = computed(() => categories.map(([id, label]) => ({ id, label, tables: tables.value.filter(table => table.category === id) })).filter(group => group.tables.length || ['master', 'transaction', 'log'].includes(group.id)))
const pageDisabled = computed(() => busy.value || sql.value !== executedSql.value)
const message = failure => failure instanceof ApiError ? failure.message : '通信に失敗しました。'
onMounted(async () => {
  try { tables.value = (await request('/api/db-schema')).tables }
  catch (failure) { schemaError.value = message(failure) }
})
async function showSchema(table) {
  if (schemaBusy.value) return
  schema.value = { table, columns: [] }; schemaError.value = ''; schemaBusy.value = true
  dialog.value.showModal()
  try { schema.value = await request('/api/db-schema?table=' + encodeURIComponent(table)) }
  catch (failure) { schemaError.value = message(failure) }
  finally { schemaBusy.value = false }
}
async function execute(page = 1) {
  if (busy.value) return
  if (page === 1) executedSql.value = sql.value
  busy.value = true; error.value = ''; result.value = null
  try {
    const { token } = await request('/api/csrf')
    result.value = await request('/api/sql-query', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
      body: JSON.stringify({ sql: executedSql.value, page }),
    })
  } catch (failure) { error.value = message(failure) }
  finally { busy.value = false }
}
</script>
<template>
  <header class="app-head"><strong>開発ツール</strong><span>DB確認</span></header>
  <main class="sql-console">
    <aside aria-label="テーブル一覧">
      <h2>テーブル</h2>
      <p v-if="schemaError && !dialog?.open" role="alert">{{ schemaError }}</p>
      <section v-for="group in groups" :key="group.id">
        <h3>{{ group.label }}</h3>
        <ul><li v-for="table in group.tables" :key="table.name"><button class="table-name" title="ダブルクリックまたはEnterで列・型を表示" @dblclick="showSchema(table.name)" @keydown.enter.prevent="showSchema(table.name)" @keydown.space.prevent="showSchema(table.name)">{{ table.name }}</button></li></ul>
        <span v-if="!group.tables.length" class="empty">なし</span>
      </section>
    </aside>
    <div class="sql-workspace">
      <h1>DB確認 <small>読み取り専用</small></h1>
      <form @submit.prevent="execute()">
        <label for="sql-input">SQL</label>
        <textarea id="sql-input" v-model="sql" spellcheck="false" maxlength="10000" :disabled="busy" />
        <div class="sql-actions">
          <button class="btn btn-secondary" type="submit" :disabled="busy || !sql.trim()">{{ busy ? '実行中…' : '実行' }}</button>
          <a class="btn btn-secondary" href="/">閉じる</a>
        </div>
      </form>
      <p v-if="error" class="form-message" role="alert">{{ error }}</p>
      <section v-if="result" aria-label="実行結果">
        <div class="result-toolbar">
          <span role="status">{{ result.rows.length }}行表示</span>
          <nav aria-label="結果のページ送り"><button class="btn btn-secondary" :disabled="pageDisabled || result.page === 1" @click="execute(result.page - 1)">前へ</button><span>{{ result.page }}ページ（200行／ページ）</span><button class="btn btn-secondary" :disabled="pageDisabled || !result.has_next" @click="execute(result.page + 1)">次へ</button></nav>
        </div>
        <div class="sql-result" tabindex="0" aria-label="SQL結果表">
          <table><thead><tr><th v-for="(column, index) in result.columns" :key="index" scope="col">{{ column }}</th></tr></thead>
            <tbody><tr v-for="(row, index) in result.rows" :key="index"><td v-for="(value, column) in row" :key="column"><span v-if="value === null" class="sql-null">NULL</span><template v-else>{{ value }}</template></td></tr></tbody>
          </table>
        </div>
      </section>
    </div>
  </main>
  <dialog ref="dialog" aria-labelledby="schema-title">
    <header class="dialog-head"><h2 id="schema-title">{{ schema?.table }} — スキーマ</h2></header>
    <div class="dialog-body">
      <p v-if="schemaBusy" role="status">読み込み中…</p><p v-else-if="schemaError" role="alert">{{ schemaError }}</p>
      <div v-else class="sql-result"><table><thead><tr><th>列</th><th>型</th><th>NULL許容</th><th>主キー</th></tr></thead><tbody><tr v-for="column in schema?.columns" :key="column.name"><td>{{ column.name }}</td><td>{{ column.type || '型指定なし' }}</td><td>{{ column.nullable ? '可' : '不可' }}</td><td>{{ column.primary_key ? '○' : '' }}</td></tr></tbody></table></div>
    </div>
    <footer class="dialog-foot"><button class="btn btn-secondary" @click="dialog.close()">閉じる</button></footer>
  </dialog>
</template>
<style scoped>
.sql-console { margin: 16px; display: grid; grid-template-columns: 230px minmax(0, 1fr); gap: 16px; }
aside { background: white; border: 1px solid #adb5bd; padding: 12px; overflow-wrap: anywhere; }
h1, h2 { font-size: 18px; } h1 small { font-size: 12px; color: #6c757d; margin-left: 12px; }
h3 { font-size: 13px; background: #e9ecef; padding: 5px; margin: 12px 0 4px; }
ul { list-style: none; margin: 0; padding: 0; }
.table-name { background: transparent; border: 0; text-align: left; padding: 5px; width: 100%; overflow-wrap: anywhere; }
.table-name:hover, .table-name:focus { background: #e9ecef; }
.empty { color: #6c757d; padding-left: 5px; }
label { display: block; font-weight: 600; margin-bottom: 6px; }
textarea { display: block; width: 100%; min-height: 130px; padding: 10px; border: 1px solid #adb5bd; font: 14px/1.5 Consolas, monospace; resize: vertical; }
.sql-actions { margin: 8px 0; display: flex; justify-content: space-between; align-items: center; gap: 8px; }
.result-toolbar, nav { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.result-toolbar { justify-content: space-between; margin-bottom: 8px; }
.sql-result { overflow: auto; max-height: 55vh; background: white; border: 1px solid #adb5bd; padding: 0; }
/* collapsed borderの隙間を避け、固定ヘッダ全体を不透明な面にする。 */
table { border-collapse: separate; border-spacing: 0; width: 100%; }
thead { position: sticky; top: 0; z-index: 1; background: #e9ecef; }
th { background: #e9ecef; white-space: nowrap; }
th, td { padding: 4px 8px; border-right: 1px solid #ced4da; border-bottom: 1px solid #ced4da; }
td { white-space: pre-wrap; min-width: 70px; max-width: 400px; overflow-wrap: anywhere; }
.sql-null { color: #6c757d; font-style: italic; }
.dialog-foot { justify-content: flex-end; }
@media (max-width: 650px) { .sql-console { grid-template-columns: minmax(0, 1fr); } aside { max-height: 210px; overflow: auto; } }
</style>
