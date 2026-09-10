<script setup>
// 診療科フォームの呼び出し元。フォームから保存結果を受け取り、画面上の完了通知へ変換する。
// 一覧は別Issueのため、内部ID指定は登録後の取得・編集を学ぶための最小の呼び出し手段として置く。
import { nextTick, ref } from 'vue'
import DepartmentForm from './DepartmentForm.vue'

const active = ref(false)
const departmentId = ref(null)
const editId = ref('')
const notice = ref('')
const opener = ref(null)

function open(id, event) {
  if (id && !/^[1-9][0-9]*$/.test(String(id))) {
    notice.value = '内部IDは正の整数で指定してください。'
    return
  }
  opener.value = event?.currentTarget || document.querySelector('#department-new')
  departmentId.value = id || null
  active.value = true
}

async function close(result) {
  active.value = false
  if (result) {
    editId.value = String(result.department.id)
    const action = result.updated ? '更新しました。' : '登録しました。'
    notice.value = `診療科ID ${result.department.id}（${result.department.name}）を${action}`
  }
  // ダイアログ要素がDOMから消えた後に、開いたボタンへ戻す。
  await nextTick()
  opener.value?.focus()
}
</script>

<template>
  <header class="app-head"><strong>外来業務</strong><span>システム管理</span></header>
  <main class="host">
    <h1>診療科マスタ</h1>
    <p><a href="/tools/sql" target="_blank" rel="noopener">DB確認（SQL）を開く</a></p>
    <p class="text-secondary">ローカル学習用・架空データ限定。診療科一覧・検索は未実装です。</p>
    <div class="host-toolbar">
      <button id="department-new" type="button" class="btn btn-secondary" @click="open(null, $event)">新規</button>
      <label for="department-edit-id">内部ID（呼び出し確認用）</label>
      <input id="department-edit-id" v-model="editId" class="form-control" inputmode="numeric">
      <button type="button" class="btn btn-secondary" @click="open(editId || 'invalid', $event)">編集</button>
    </div>
    <p v-if="notice" class="host-notice" role="status">{{ notice }}</p>
  </main>
  <DepartmentForm v-if="active" :department-id="departmentId" @close="close" />
</template>
