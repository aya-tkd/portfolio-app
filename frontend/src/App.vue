<script setup>
// アプリ全体の入口。患者機能の詳細はfeatures/patientsへ委譲する。
import PatientWorkspace from './features/patients/components/PatientWorkspace.vue'
import SqlConsole from './features/development/components/SqlConsole.vue'
const sqlConsole = location.pathname === '/tools/sql'
</script>

<template>
  <SqlConsole v-if="sqlConsole" />
  <PatientWorkspace v-else />
</template>
