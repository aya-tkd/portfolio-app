<script setup>
// アプリ全体の入口。URLで業務機能を選び、各機能の詳細はfeatures配下へ委譲する。
import PatientWorkspace from './features/patients/components/PatientWorkspace.vue'
import DepartmentWorkspace from './features/administration/departments/components/DepartmentWorkspace.vue'
import OccupationWorkspace from './features/administration/occupations/components/OccupationWorkspace.vue'
import SqlConsole from './features/development/components/SqlConsole.vue'
const sqlConsole = location.pathname === '/tools/sql'
const departmentMaster = location.pathname === '/masters/departments'
const occupationMaster = location.pathname === '/masters/occupations'
</script>

<template>
  <SqlConsole v-if="sqlConsole" />
  <DepartmentWorkspace v-else-if="departmentMaster" />
  <OccupationWorkspace v-else-if="occupationMaster" />
  <PatientWorkspace v-else />
</template>
