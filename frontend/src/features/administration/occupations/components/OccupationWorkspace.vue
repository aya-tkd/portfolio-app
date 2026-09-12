<script setup>
// 職種フォームの呼び出し元。保存結果を受けて親画面の完了通知に表示する。
import { nextTick, ref } from 'vue'
import OccupationForm from './OccupationForm.vue'

const active = ref(false), occupationId = ref(null), editId = ref(''), notice = ref(''), opener = ref(null)
function open(id, event) {
  if (id && !/^[1-9][0-9]*$/.test(String(id))) { notice.value = '内部IDは正の整数で指定してください。'; return }
  opener.value = event?.currentTarget || document.querySelector('#occupation-new')
  occupationId.value = id || null
  active.value = true
}
async function close(result) {
  active.value = false
  if (result) {
    editId.value = String(result.occupation.id)
    notice.value = `職種ID ${result.occupation.id}（${result.occupation.name}）を${result.updated ? '更新しました。' : '登録しました。'}`
  }
  await nextTick()
  opener.value?.focus()
}
</script>

<template>
  <header class="app-head"><strong>外来業務</strong><span>システム管理</span></header>
  <main class="host">
    <h1>職種マスタ</h1>
    <p><a href="/tools/sql" target="_blank" rel="noopener">DB確認（SQL）を開く</a></p>
    <p class="text-secondary">ローカル学習用・架空データ限定。職種一覧・検索と権限管理は未実装です。</p>
    <div class="host-toolbar"><button id="occupation-new" type="button" class="btn btn-secondary" @click="open(null, $event)">新規</button><label for="occupation-edit-id">内部ID（呼び出し確認用）</label><input id="occupation-edit-id" v-model="editId" class="form-control" inputmode="numeric"><button type="button" class="btn btn-secondary" @click="open(editId || 'invalid', $event)">編集</button></div>
    <p v-if="notice" class="host-notice" role="status">{{ notice }}</p>
  </main>
  <OccupationForm v-if="active" :occupation-id="occupationId" @close="close" />
</template>
