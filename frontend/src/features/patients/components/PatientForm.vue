<script setup>
// PatientWorkspace.vueから内部IDを受け取る患者フォーム。IDなしなら新規、ありならAPIで読み込む。
// 入力・送信中・エラー・破棄確認はVue、検証とDB保存はRailsが担当する。
// 成功時はcloseイベントに結果を載せ、通信失敗では入力を保持して自動再送しない。
import { ref, reactive, computed, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { ApiError } from '../../../shared/api/http.js'
import { loadPatient, savePatient } from '../api.js'

const props = defineProps({ patientId: { type: [String, Number], default: null } })
const emit = defineEmits(['close'])
const dialog = ref(), form = ref(), discard = ref(false), resume = ref()
const busy = ref(false), loadFailed = ref(false), uncertain = ref(false)
const number = ref('自動発行'), message = ref(''), errors = ref({}), original = ref('')
const fields = [
  { key: 'last_name', label: '姓' }, { key: 'first_name', label: '名' },
  { key: 'last_name_kana', label: 'セイ' }, { key: 'first_name_kana', label: 'メイ' },
]
const values = reactive({ last_name: '', first_name: '', last_name_kana: '', first_name_kana: '', birth_date: '', sex: '' })
const dirty = computed(() => JSON.stringify(values) !== original.value)
// 再読込やページ離脱は、モーダル内の「閉じる」とは別経路なのでブラウザ標準の確認を使う。
function focusFirst() { form.value?.querySelector('input')?.focus() }
function beforeUnload(event) { if (dirty.value || busy.value) { event.preventDefault(); event.returnValue = '' } }
async function close() {
  if (busy.value) return
  if (dirty.value) { discard.value = true; await nextTick(); resume.value?.focus() }
  else emit('close')
}
async function resumeEdit() { discard.value = false; await nextTick(); focusFirst() }
function trapTab(event) {
  if (event.key !== 'Tab') return
  const items = [...dialog.value.querySelectorAll('input,select,button')].filter(el => !el.disabled && el.getClientRects().length)
  const first = items[0], last = items.at(-1)
  if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus() }
  else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus() }
}
async function save() {
  if (busy.value || discard.value || loadFailed.value || uncertain.value) return
  errors.value = {}; message.value = ''; busy.value = true
  try {
    const saved = await savePatient(props.patientId, { ...values, birth_date: values.birth_date || null })
    original.value = JSON.stringify(values)
    emit('close', saved)
  } catch (error) {
    if (error instanceof ApiError && error.status < 500) {
      errors.value = error.errors
      message.value = error.message
    } else {
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
  // VueがHTML要素を作った後に呼ぶ。dialogを開き、編集時だけ保存済みデータを取得する。
  original.value = JSON.stringify(values)
  dialog.value.showModal()
  window.addEventListener('beforeunload', beforeUnload)
  if (props.patientId) {
    busy.value = true
    try {
      const patient = await loadPatient(props.patientId)
      for (const key of Object.keys(values)) values[key] = patient[key] ?? ''
      number.value = patient.patient_number
      original.value = JSON.stringify(values)
    } catch (error) {
      loadFailed.value = true
      message.value = error instanceof ApiError ? error.message : '読み込みに失敗しました。閉じてから再度開いてください。'
    } finally { busy.value = false }
  }
  await nextTick()
  if (loadFailed.value) dialog.value.querySelector('#close').focus()
  else focusFirst()
})
onBeforeUnmount(() => window.removeEventListener('beforeunload', beforeUnload))
</script>

<template>
  <dialog ref="dialog" aria-labelledby="dialog-title" @cancel.prevent="close" @keydown="trapTab">
    <header class="dialog-head"><h2 id="dialog-title">{{ patientId ? '患者編集' : '患者登録' }}</h2><span class="mode">{{ patientId ? '編集' : '新規' }}</span></header>
    <form ref="form" novalidate @submit.prevent="save" @keydown="e => { if (e.key === 'Enter' && e.target.tagName === 'INPUT') e.preventDefault() }">
      <div class="dialog-body">
        <div class="identity">患者番号 <strong>{{ number }}</strong><span>基本情報</span></div>
        <p v-if="message" class="form-message" role="alert">{{ message }}</p>
        <p v-if="busy" role="status">処理中です…</p>
        <p class="section-heading">患者情報</p>
        <fieldset :disabled="busy || loadFailed" class="fields">
          <div v-for="field in fields" :key="field.key" class="field">
            <label :for="field.key">{{ field.label }}<span class="required" aria-label="必須">＊</span></label>
            <div><input :id="field.key" v-model="values[field.key]" class="form-control" required maxlength="100" autocomplete="off" :aria-invalid="!!errors[field.key]" :aria-describedby="`${field.key}-error`">
              <p :id="`${field.key}-error`" class="field-error">{{ errors[field.key]?.join(' ') }}</p></div>
          </div>
          <div class="field"><label for="birth_date">生年月日</label><div><input id="birth_date" v-model="values.birth_date" type="date" class="form-control" :aria-invalid="!!errors.birth_date" aria-describedby="birth_date-error"><p id="birth_date-error" class="field-error">{{ errors.birth_date?.join(' ') }}</p></div></div>
          <div class="field"><label for="sex">性別</label><div><select id="sex" v-model="values.sex" class="form-select" :aria-invalid="!!errors.sex" aria-describedby="sex-error"><option value="">未設定</option><option value="male">男性</option><option value="female">女性</option><option value="other">その他</option></select><p id="sex-error" class="field-error">{{ errors.sex?.join(' ') }}</p></div></div>
        </fieldset>
        <section v-if="discard" class="discard" role="alert"><p><span aria-hidden="true">⚠</span> 入力中の変更を破棄して閉じますか？</p><div class="buttons"><button ref="resume" type="button" class="btn btn-secondary" @click="resumeEdit">戻る</button><button type="button" class="btn btn-secondary" @click="emit('close')"><span aria-hidden="true">⚠</span> 中止</button></div></section>
      </div>
      <footer class="dialog-foot"><span>＊ 必須項目</span><div class="buttons"><button type="submit" class="btn btn-primary" :disabled="busy || discard || loadFailed || uncertain">登録</button><button id="close" type="button" class="btn btn-secondary" :disabled="busy" @click="close">閉じる</button></div></footer>
    </form>
  </dialog>
</template>
