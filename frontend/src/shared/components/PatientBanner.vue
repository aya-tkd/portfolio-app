<script setup>
// 患者を特定した後の業務画面上部へ固定表示する患者情報パネルである。
// 親画面から患者DTOを受け取るだけでAPIは呼ばず、患者取り違えを防ぐ共通表示に専念する。
defineProps({ patient: { type: Object, required: true } })

const sexLabel = value => ({ male: '男性', female: '女性', other: 'その他' }[value] || '未入力')
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
    <div class="patient-banner__identity"><span class="patient-banner__number">患者No. {{ patient.patient_number }}</span><strong>{{ patient.last_name }} {{ patient.first_name }}</strong><span>{{ patient.last_name_kana }} {{ patient.first_name_kana }}</span></div>
    <dl class="patient-banner__details"><div><dt>生年月日</dt><dd>{{ patient.birth_date || '未入力' }} <small>{{ age(patient.birth_date) }}</small></dd></div><div><dt>性別</dt><dd>{{ sexLabel(patient.sex) }}</dd></div></dl>
  </section>
</template>

<style scoped>
.patient-banner{position:sticky;top:0;z-index:3;display:flex;justify-content:space-between;gap:20px;padding:10px 16px;background:#e8f0f7;border:1px solid #9db2c4;border-left:4px solid #45647f}.patient-banner__identity{display:flex;align-items:baseline;gap:12px;flex-wrap:wrap}.patient-banner__identity strong{font-size:20px}.patient-banner__number{font-weight:700;color:#29465f}.patient-banner__details{display:flex;gap:18px;margin:0}.patient-banner__details div{display:flex;gap:7px}.patient-banner__details dt{color:#4e5c68}.patient-banner__details dd{margin:0;font-weight:600}.patient-banner small{font-weight:400;color:#4e5c68}@media(max-width:700px){.patient-banner{align-items:flex-start;flex-direction:column;gap:8px}}
</style>
