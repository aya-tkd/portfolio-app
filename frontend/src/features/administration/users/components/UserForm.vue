<script setup>
// UserMasterPaneから編集IDと関連マスタを受け取る埋め込みフォーム。
// 診療科・職種フォームと同じ共通CSSを使い、保存成功時にレコードを親へ返す。
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { ApiError } from '../../../../shared/api/http.js'
import { loadUser, saveUser } from '../api.js'

const props = defineProps({ userId: { type: Number, default: null }, departments: { type: Array, required: true }, occupations: { type: Array, required: true } })
const emit = defineEmits(['close'])
const form = ref(), resume = ref()
const busy = ref(false), loadFailed = ref(false), uncertain = ref(false), discard = ref(false)
const message = ref(''), errors = ref({}), original = ref('')
const values = reactive({ last_name: '', first_name: '', last_name_kana: '', first_name_kana: '', department_id: '', occupation_id: '', active: true })
const nameFields = [
  { key: 'last_name', label: '姓' }, { key: 'first_name', label: '名' },
  { key: 'last_name_kana', label: 'セイ' }, { key: 'first_name_kana', label: 'メイ' },
]
const dirty = computed(() => JSON.stringify(values) !== original.value)
function focusFirst() { form.value?.querySelector('#user-last_name')?.focus() }
function beforeUnload(event) {
  if (dirty.value || busy.value) { event.preventDefault(); event.returnValue = '' }
}
async function close() {
  if (busy.value) return
  if (!dirty.value) { emit('close'); return }
  discard.value = true
  await nextTick()
  resume.value?.focus()
}
async function resumeEdit() { discard.value = false; await nextTick(); focusFirst() }
async function save() {
  if (busy.value || discard.value || loadFailed.value || uncertain.value) return
  busy.value = true
  errors.value = {}
  message.value = ''
  try {
    const user = await saveUser(props.userId, { ...values, department_id: values.department_id || null, occupation_id: values.occupation_id || null })
    original.value = JSON.stringify(values)
    emit('close', user)
  } catch (error) {
    if (error instanceof ApiError && error.status < 500) {
      errors.value = error.errors
      message.value = error.message
    } else {
      // 通信失敗でもDB保存が終わった可能性があるため、重複登録につながる再送を止める。
      uncertain.value = true
      message.value = '保存結果を確認できません。自動再送はしません。登録済みかを確認してから操作してください。'
    }
  } finally {
    busy.value = false
    await nextTick()
    form.value?.querySelector('[aria-invalid="true"]')?.focus()
  }
}
onMounted(async () => {
  // フォーム描画後、編集時だけ既存レコードを取得する。新規時は最初の入力へフォーカスする。
  original.value = JSON.stringify(values)
  window.addEventListener('beforeunload', beforeUnload)
  if (props.userId) {
    busy.value = true
    try {
      const user = await loadUser(props.userId)
      for (const key of Object.keys(values)) values[key] = user[key] ?? ''
      original.value = JSON.stringify(values)
    } catch (error) { loadFailed.value = true; message.value = error.message || '読み込みに失敗しました。閉じてから再度開いてください。' }
    finally { busy.value = false }
  }
  await nextTick()
  if (loadFailed.value) form.value?.querySelector('#user-close')?.focus()
  else focusFirst()
})
onBeforeUnmount(() => window.removeEventListener('beforeunload', beforeUnload))
</script>

<template>
  <section class="master-form" aria-labelledby="user-dialog-title">
    <header class="dialog-head"><h2 id="user-dialog-title">{{ userId ? 'ユーザー編集' : 'ユーザー登録' }}</h2><span class="mode">{{ userId ? '編集' : '新規' }}</span></header>
    <form ref="form" novalidate @submit.prevent="save" @keydown="event => { if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault() }">
      <div class="dialog-body">
        <div class="identity">ユーザーID <strong id="user-id">{{ userId || '自動採番（保存時）' }}</strong><span>基本情報</span></div>
        <p v-if="message" class="form-message" role="alert">{{ message }}</p>
        <p v-if="busy" role="status">処理中です…</p>
        <p class="section-heading">ユーザー情報</p>
        <fieldset :disabled="busy || loadFailed" class="fields">
          <div v-for="field in nameFields" :key="field.key" class="field">
            <label :for="`user-${field.key}`">{{ field.label }}<span class="required" aria-label="必須">＊</span></label>
            <div><input :id="`user-${field.key}`" v-model="values[field.key]" class="form-control" required maxlength="100" autocomplete="off" :aria-invalid="!!errors[field.key]" :aria-describedby="`user-${field.key}-error`"><p :id="`user-${field.key}-error`" class="field-error">{{ errors[field.key]?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="user-department">診療科</label>
            <div><select id="user-department" v-model="values.department_id" class="form-select" :aria-invalid="!!errors.department_id" aria-describedby="user-department-error"><option value="">未設定</option><option v-for="department in departments" :key="department.id" :value="department.id">{{ department.name }}</option></select><p id="user-department-error" class="field-error">{{ errors.department_id?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="user-occupation">職種</label>
            <div><select id="user-occupation" v-model="values.occupation_id" class="form-select" :aria-invalid="!!errors.occupation_id" aria-describedby="user-occupation-error"><option value="">未設定</option><option v-for="occupation in occupations" :key="occupation.id" :value="occupation.id">{{ occupation.name }}</option></select><p id="user-occupation-error" class="field-error">{{ errors.occupation_id?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="user-active">利用状態<span class="required" aria-label="必須">＊</span></label>
            <div><select id="user-active" v-model="values.active" class="form-select" :aria-invalid="!!errors.active" aria-describedby="user-active-error"><option :value="true">有効</option><option :value="false">無効</option></select><p id="user-active-error" class="field-error">{{ errors.active?.join(' ') }}</p></div>
          </div>
        </fieldset>
        <section v-if="discard" class="discard" role="alert"><p><span aria-hidden="true">⚠</span> 入力中の変更を破棄して閉じますか？</p><div class="buttons"><button ref="resume" type="button" class="btn btn-secondary" @click="resumeEdit">戻る</button><button type="button" class="btn btn-secondary" @click="emit('close')"><span aria-hidden="true">⚠</span> 中止</button></div></section>
      </div>
      <footer class="dialog-foot"><span>＊ 必須項目</span><div class="buttons"><button type="submit" class="btn btn-primary" :disabled="busy || discard || loadFailed || uncertain">登録</button><button id="user-close" type="button" class="btn btn-secondary" :disabled="busy" @click="close">閉じる</button></div></footer>
    </form>
  </section>
</template>
