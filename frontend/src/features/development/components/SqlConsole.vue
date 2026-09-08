<script setup>
// ローカルDBの読み取り確認用。SQLをAPIへ送り、列名と行配列を表へ表示する。
// DB接続や実行可否はRails側で決め、エラー時も入力したSQLを保持する。
import { ref } from 'vue'
import { request, ApiError } from '../../../shared/api/http.js'

const sql = ref('SELECT * FROM patients ORDER BY id DESC;')
const busy = ref(false), result = ref(null), error = ref('')
async function execute() {
  if (busy.value) return
  busy.value = true; error.value = ''; result.value = null
  try {
    const { token } = await request('/api/csrf')
    result.value = await request('/api/sql-query', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
      body: JSON.stringify({ sql: sql.value }),
    })
  } catch (failure) {
    error.value = failure instanceof ApiError ? failure.message : '通信に失敗しました。ローカル環境の起動状態を確認してください。'
  } finally { busy.value = false }
}
</script>

<template>
  <header class="app-head"><strong>開発ツール</strong><span>DB確認</span></header>
  <main class="sql-console">
    <h1>DB確認（SQL）</h1>
    <p>ローカル開発DB・読み取り専用。1文ずつ実行できます。結果は最大200行、長いセルは省略します。</p>
    <form @submit.prevent="execute">
      <label for="sql-input">SQL</label>
      <textarea id="sql-input" v-model="sql" spellcheck="false" maxlength="10000" :disabled="busy" />
      <div class="sql-actions"><button class="btn btn-secondary" type="submit" :disabled="busy || !sql.trim()">{{ busy ? '実行中…' : '実行' }}</button></div>
    </form>
    <details><summary>テーブルを確認するSQL例</summary><pre>SELECT name, sql FROM sqlite_schema WHERE type = 'table';</pre></details>
    <p v-if="error" class="form-message" role="alert">{{ error }}</p>
    <section v-if="result" aria-label="実行結果">
      <p role="status">{{ result.rows.length }}行表示<span v-if="result.truncated">（上限{{ result.limit }}行まで。条件で絞り込んでください）</span></p>
      <div class="sql-result" tabindex="0" aria-label="SQL結果表">
        <table class="table table-sm table-bordered"><thead><tr><th v-for="(column, index) in result.columns" :key="index" scope="col">{{ column }}</th></tr></thead>
          <tbody><tr v-for="(row, index) in result.rows" :key="index"><td v-for="(value, column) in row" :key="column"><span v-if="value === null" class="sql-null">NULL</span><template v-else>{{ value }}</template></td></tr></tbody>
        </table>
      </div>
    </section>
    <footer class="sql-footer"><a class="btn btn-secondary" href="/">閉じる</a></footer>
  </main>
</template>

<style scoped>
.sql-console { margin: 24px; }
h1 { font-size: 20px; }
label { display: block; font-weight: 600; margin-bottom: 6px; }
textarea { display: block; width: 100%; min-height: 160px; padding: 10px; border: 1px solid #adb5bd; font: 14px/1.5 Consolas, monospace; resize: vertical; }
.sql-actions { margin: 10px 0; }
details { margin: 12px 0; }
pre { padding: 8px; white-space: pre-wrap; }
.sql-result { overflow: auto; max-height: 55vh; background: white; }
th { position: sticky; top: 0; background: #e9ecef; white-space: nowrap; }
td { white-space: pre-wrap; min-width: 70px; max-width: 400px; overflow-wrap: anywhere; }
.sql-null { color: #6c757d; font-style: italic; }
.sql-footer { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>
