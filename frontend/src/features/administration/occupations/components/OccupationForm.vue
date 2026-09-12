<script setup>
// OccupationWorkspaceからIDを受け取る職種フォーム。IDなしは新規、ありはAPIから取得して更新する。
// 入力状態と未保存確認はVue、検証とSQLite保存はRailsが担当し、成功結果を親へ返す。
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { ApiError } from '../../../../shared/api/http.js'
import { loadOccupation, saveOccupation } from '../api.js'

const props = defineProps({ occupationId: { type: [String, Number], default: null } })
const emit = defineEmits(['close'])
const dialog = ref(), form = ref(), resume = ref(), busy = ref(false), loadFailed = ref(false), uncertain = ref(false), discard = ref(false)
const number = ref('自動採番（保存時）'), message = ref(''), errors = ref({}), original = ref('')
const values = reactive({ name: '', display_order: 1, active: true })
const dirty = computed(() => JSON.stringify(values) !== original.value)
function focusFirst() { form.value?.querySelector('#occupation-name')?.focus() }
function beforeUnload(event) { if (dirty.value || busy.value) { event.preventDefault(); event.returnValue = '' } }
async function close() { if (busy.value) return; if (dirty.value) { discard.value = true; await nextTick(); resume.value?.focus() } else emit('close') }
async function resumeEdit() { discard.value = false; await nextTick(); focusFirst() }
function trapTab(event) { if (event.key !== 'Tab') return; const items = [...dialog.value.querySelectorAll('input,select,button')].filter(element => !element.disabled && element.getClientRects().length); const first = items[0], last = items.at(-1); if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus() } else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus() } }
async function save() {
  if (busy.value || discard.value || loadFailed.value || uncertain.value) return
  errors.value = {}; message.value = ''; busy.value = true
  try { const occupation = await saveOccupation(props.occupationId, { ...values }); original.value = JSON.stringify(values); emit('close', { occupation, updated: Boolean(props.occupationId) }) }
  catch (error) { if (error instanceof ApiError && error.status < 500) { errors.value = error.errors; message.value = error.message } else { uncertain.value = true; message.value = '保存結果を確認できません。自動再送はしません。登録済みかを確認してから操作してください。' } }
  finally { busy.value = false; await nextTick(); form.value?.querySelector('[aria-invalid="true"]')?.focus() }
}
onMounted(async () => {
  original.value = JSON.stringify(values); dialog.value.showModal(); window.addEventListener('beforeunload', beforeUnload)
  if (props.occupationId) { busy.value = true; try { const occupation = await loadOccupation(props.occupationId); for (const key of Object.keys(values)) values[key] = occupation[key]; number.value = occupation.id; original.value = JSON.stringify(values) } catch (error) { loadFailed.value = true; message.value = error instanceof ApiError ? error.message : '読み込みに失敗しました。閉じてから再度開いてください。' } finally { busy.value = false } }
  await nextTick(); if (loadFailed.value) dialog.value.querySelector('#occupation-close').focus(); else focusFirst()
})
onBeforeUnmount(() => window.removeEventListener('beforeunload', beforeUnload))
</script>

<template>
  <dialog ref="dialog" aria-labelledby="occupation-dialog-title" @cancel.prevent="close" @keydown="trapTab">
    <header class="dialog-head"><h2 id="occupation-dialog-title">{{ occupationId ? '職種編集' : '職種登録' }}</h2><span class="mode">{{ occupationId ? '編集' : '新規' }}</span></header>
    <form ref="form" novalidate @submit.prevent="save" @keydown="event => { if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault() }">
      <div class="dialog-body"><div class="identity">職種ID <strong id="occupation-id">{{ number }}</strong><span>基本情報</span></div><p v-if="message" class="form-message" role="alert">{{ message }}</p><p v-if="busy" role="status">処理中です…</p><p class="section-heading">職種情報</p>
        <fieldset :disabled="busy || loadFailed" class="fields"><div class="field field-wide"><label for="occupation-name">職種名<span class="required" aria-label="必須">＊</span></label><div><input id="occupation-name" v-model="values.name" class="form-control" required maxlength="100" autocomplete="off" :aria-invalid="!!errors.name" aria-describedby="occupation-name-error"><p id="occupation-name-error" class="field-error">{{ errors.name?.join(' ') }}</p></div></div><div class="field"><label for="occupation-display-order">表示順<span class="required" aria-label="必須">＊</span></label><div><input id="occupation-display-order" v-model.number="values.display_order" class="form-control" type="number" min="1" required inputmode="numeric" :aria-invalid="!!errors.display_order" aria-describedby="occupation-display-order-error"><p id="occupation-display-order-error" class="field-error">{{ errors.display_order?.join(' ') }}</p></div></div><div class="field"><label for="occupation-active">利用状態<span class="required" aria-label="必須">＊</span></label><div><select id="occupation-active" v-model="values.active" class="form-select" :aria-invalid="!!errors.active" aria-describedby="occupation-active-error"><option :value="true">有効</option><option :value="false">無効</option></select><p id="occupation-active-error" class="field-error">{{ errors.active?.join(' ') }}</p></div></div></fieldset>
        <section v-if="discard" class="discard" role="alert"><p><span aria-hidden="true">⚠</span> 入力中の変更を破棄して閉じますか？</p><div class="buttons"><button ref="resume" type="button" class="btn btn-secondary" @click="resumeEdit">戻る</button><button type="button" class="btn btn-secondary" @click="emit('close')"><span aria-hidden="true">⚠</span> 中止</button></div></section>
      </div>
      <footer class="dialog-foot"><span>＊ 必須項目</span><div class="buttons"><button type="submit" class="btn btn-primary" :disabled="busy || discard || loadFailed || uncertain">登録</button><button id="occupation-close" type="button" class="btn btn-secondary" :disabled="busy" @click="close">閉じる</button></div></footer>
    </form>
  </dialog>
</template>
