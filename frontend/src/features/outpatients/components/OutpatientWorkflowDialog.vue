<script setup>
// 外来一覧から開く業務ダイアログの共通枠。
// OutpatientListWorkspace が呼び出し元となり、mode を業務名として表示し、本文は slot の各業務 Vue が担当する。
defineProps({
  mode: { type: String, required: true },
})
</script>

<template>
  <div class="workflow-overlay">
    <section class="outpatient-workflow-dialog" role="dialog" aria-modal="true" :aria-label="`外来業務：${mode}`">
      <header class="outpatient-workflow-dialog__head">
        <strong>外来業務</strong>
        <span>{{ mode }}</span>
      </header>
      <div class="outpatient-workflow-dialog__body"><slot /></div>
    </section>
  </div>
</template>

<style scoped>
.workflow-overlay{position:fixed;inset:0;z-index:20;display:grid;place-items:center;padding:24px;background:#29323b80}
.outpatient-workflow-dialog{display:flex;flex-direction:column;width:min(1100px,calc(100vw - 32px));height:min(860px,calc(100dvh - 48px));overflow:hidden;background:#f1f3f5;border:1px solid #7b858f;box-shadow:0 8px 24px #0004}
.outpatient-workflow-dialog__head{display:flex;align-items:center;gap:24px;flex:0 0 44px;padding:0 20px;background:#e2e6ea;border-bottom:1px solid #adb5bd}.outpatient-workflow-dialog__head strong{font-size:16px}.outpatient-workflow-dialog__head span{font-weight:600}
.outpatient-workflow-dialog__body{display:flex;flex:1;min-height:0;overflow:auto}
@media(max-width:760px){.workflow-overlay{padding:12px}.outpatient-workflow-dialog{width:calc(100vw - 24px);height:calc(100dvh - 24px)}.outpatient-workflow-dialog__head{padding:0 14px}}
</style>
