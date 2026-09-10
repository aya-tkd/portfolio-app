<script setup>
// DepartmentWorkspace.vueから内部IDを受け取る診療科フォーム。IDなしなら新規、ありならAPIで取得・更新する。
// 入力・送信中・破棄確認はVue、検証とSQLite保存はRailsが担当する。成功時は保存結果を親へ返す。
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { ApiError } from '../../../../shared/api/http.js'
import { loadDepartment, saveDepartment } from '../api.js'

const props = defineProps({ departmentId: { type: [String, Number], default: null } })
const emit = defineEmits(['close'])
const dialog = ref()
const form = ref()
const resume = ref()
const busy = ref(false)
const loadFailed = ref(false)
const uncertain = ref(false)
const discard = ref(false)
const message = ref('')
const errors = ref({})
const original = ref('')
const number = ref('自動採番（保存時）')
const values = reactive({ name: '', kana_name: '', abbreviation: '', display_order: 1, active: true })
const dirty = computed(() => JSON.stringify(values) !== original.value)

function focusFirst() { form.value?.querySelector('#department-name')?.focus() }
function beforeUnload(event) {
  if (dirty.value || busy.value) {
    event.preventDefault()
    event.returnValue = ''
  }
}

async function close() {
  if (busy.value) return
  if (dirty.value) {
    discard.value = true
    await nextTick()
    resume.value?.focus()
  } else {
    emit('close')
  }
}

async function resumeEdit() {
  discard.value = false
  await nextTick()
  focusFirst()
}

function trapTab(event) {
  if (event.key !== 'Tab') return
  const items = [...dialog.value.querySelectorAll('input, select, button')]
    .filter(element => !element.disabled && element.getClientRects().length)
  const first = items[0]
  const last = items.at(-1)
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault()
    last.focus()
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault()
    first.focus()
  }
}

async function save() {
  if (busy.value || discard.value || loadFailed.value || uncertain.value) return
  errors.value = {}
  message.value = ''
  busy.value = true
  try {
    const department = await saveDepartment(props.departmentId, { ...values })
    original.value = JSON.stringify(values)
    emit('close', { department, updated: Boolean(props.departmentId) })
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
  // VueがHTML要素を配置した後にダイアログを開き、編集時のみRails APIから既存値を取得する。
  original.value = JSON.stringify(values)
  dialog.value.showModal()
  window.addEventListener('beforeunload', beforeUnload)
  if (props.departmentId) {
    busy.value = true
    try {
      const department = await loadDepartment(props.departmentId)
      for (const key of Object.keys(values)) values[key] = department[key]
      number.value = department.id
      original.value = JSON.stringify(values)
    } catch (error) {
      loadFailed.value = true
      message.value = error instanceof ApiError ? error.message : '読み込みに失敗しました。閉じてから再度開いてください。'
    } finally {
      busy.value = false
    }
  }
  await nextTick()
  if (loadFailed.value) dialog.value.querySelector('#department-close').focus()
  else focusFirst()
})

onBeforeUnmount(() => window.removeEventListener('beforeunload', beforeUnload))
</script>

<template>
  <dialog ref="dialog" aria-labelledby="department-dialog-title" @cancel.prevent="close" @keydown="trapTab">
    <header class="dialog-head">
      <h2 id="department-dialog-title">{{ departmentId ? '診療科編集' : '診療科登録' }}</h2>
      <span class="mode">{{ departmentId ? '編集' : '新規' }}</span>
    </header>
    <form ref="form" novalidate @submit.prevent="save" @keydown="event => { if (event.key === 'Enter' && event.target.tagName === 'INPUT') event.preventDefault() }">
      <div class="dialog-body">
        <div class="identity">診療科ID <strong id="department-id">{{ number }}</strong><span>基本情報</span></div>
        <p v-if="message" class="form-message" role="alert">{{ message }}</p>
        <p v-if="busy" role="status">処理中です…</p>
        <p class="section-heading">診療科情報</p>
        <fieldset :disabled="busy || loadFailed" class="fields">
          <div class="field field-wide">
            <label for="department-name">診療科名<span class="required" aria-label="必須">＊</span></label>
            <div><input id="department-name" v-model="values.name" class="form-control" required maxlength="100" autocomplete="off" :aria-invalid="!!errors.name" aria-describedby="department-name-error"><p id="department-name-error" class="field-error">{{ errors.name?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="department-kana-name">カナ名</label>
            <div><input id="department-kana-name" v-model="values.kana_name" class="form-control" maxlength="100" autocomplete="off" :aria-invalid="!!errors.kana_name" aria-describedby="department-kana-name-error"><p id="department-kana-name-error" class="field-error">{{ errors.kana_name?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="department-abbreviation">略名</label>
            <div><input id="department-abbreviation" v-model="values.abbreviation" class="form-control" maxlength="20" autocomplete="off" :aria-invalid="!!errors.abbreviation" aria-describedby="department-abbreviation-error"><p id="department-abbreviation-error" class="field-error">{{ errors.abbreviation?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="department-display-order">表示順<span class="required" aria-label="必須">＊</span></label>
            <div><input id="department-display-order" v-model.number="values.display_order" class="form-control" type="number" min="1" required inputmode="numeric" :aria-invalid="!!errors.display_order" aria-describedby="department-display-order-error"><p id="department-display-order-error" class="field-error">{{ errors.display_order?.join(' ') }}</p></div>
          </div>
          <div class="field">
            <label for="department-active">利用状態<span class="required" aria-label="必須">＊</span></label>
            <div><select id="department-active" v-model="values.active" class="form-select" :aria-invalid="!!errors.active" aria-describedby="department-active-error"><option :value="true">有効</option><option :value="false">無効</option></select><p id="department-active-error" class="field-error">{{ errors.active?.join(' ') }}</p></div>
          </div>
        </fieldset>
        <section v-if="discard" class="discard" role="alert"><p><span aria-hidden="true">⚠</span> 入力中の変更を破棄して閉じますか？</p><div class="buttons"><button ref="resume" type="button" class="btn btn-secondary" @click="resumeEdit">戻る</button><button type="button" class="btn btn-secondary" @click="emit('close')"><span aria-hidden="true">⚠</span> 中止</button></div></section>
      </div>
      <footer class="dialog-foot"><span>＊ 必須項目</span><div class="buttons"><button type="submit" class="btn btn-primary" :disabled="busy || discard || loadFailed || uncertain">登録</button><button id="department-close" type="button" class="btn btn-secondary" :disabled="busy" @click="close">閉じる</button></div></footer>
    </form>
  </dialog>
</template>
