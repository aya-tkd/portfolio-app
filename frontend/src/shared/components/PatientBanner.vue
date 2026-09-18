<script setup>
// 患者を特定した後の業務画面上部へ固定表示する患者情報パネルである。
// 親画面から患者DTOを受け取るだけでAPIは呼ばず、患者取り違えを防ぐ共通表示に専念する。
defineProps({ patient: { type: Object, required: true } })

const sexLabel = value => ({ male: '男性', female: '女性', other: 'その他' }[value] || '未入力')
const sexMark = value => ({ male: '男', female: '女' }[value] || '－')
const age = value => {
  if (!value) return '年齢未入力'
  const birthday = new Date(`${value}T00:00:00`)
  const today = new Date()
  let years = today.getFullYear() - birthday.getFullYear()
  if (today < new Date(today.getFullYear(), birthday.getMonth(), birthday.getDate())) years -= 1
  return `${years}歳`
}
</script>

<template>
  <section class="patient-banner" aria-label="患者情報">
    <div class="patient-banner__mark" :aria-label="`性別 ${sexLabel(patient.sex)}`">{{ sexMark(patient.sex) }}</div>
    <div class="patient-banner__name"><small>患者No. {{ patient.patient_number }}</small><strong>{{ patient.last_name }} {{ patient.first_name }}</strong><span>{{ patient.last_name_kana }} {{ patient.first_name_kana }}</span></div>
    <dl class="patient-banner__details"><div><dt>生年月日 / 年齢</dt><dd>{{ patient.birth_date || '未入力' }}　{{ age(patient.birth_date) }}</dd></div><div><dt>性別</dt><dd><span class="sex-chip">{{ sexLabel(patient.sex) }}</span></dd></div></dl>
    <a class="patient-banner__detail" href="/patients">患者詳細</a>
  </section>
</template>

<style scoped>
.patient-banner{position:sticky;top:0;z-index:3;display:grid;grid-template-columns:74px minmax(250px,1.2fr) minmax(270px,.8fr) auto;overflow:hidden;background:#fff;border:1px solid #8192a0;box-shadow:0 2px 5px #1a2d3c29}.patient-banner__mark{display:grid;place-items:center;background:#e9f0f6;border-right:1px solid #c4d0da;color:#284a67;font-size:22px;font-weight:700}.patient-banner__name{display:grid;align-content:center;gap:2px;padding:10px 14px;border-right:1px solid #d4dde4}.patient-banner__name small,.patient-banner__details dt{color:#536272;font-size:11px}.patient-banner__name strong{font-size:21px;letter-spacing:.04em}.patient-banner__name span{color:#536272;font-size:12px}.patient-banner__details{display:grid;grid-template-columns:1fr 1fr;margin:0}.patient-banner__details div{padding:10px 13px;border-right:1px solid #d4dde4}.patient-banner__details dd{margin:3px 0 0;font-weight:600;white-space:nowrap}.sex-chip{display:inline-block;padding:2px 8px;border:1px solid #7895ac;border-radius:12px;background:#edf4f9;color:#244864;font-size:12px}.patient-banner__detail{display:grid;place-items:center;padding:10px 16px;color:#31546f;font-weight:600}@media(max-width:760px){.patient-banner{grid-template-columns:60px 1fr}.patient-banner__details,.patient-banner__detail{grid-column:1/-1}.patient-banner__detail{justify-content:end}}
</style>
