<script setup>
// アプリ全体の入口。URLで業務機能を選び、各機能の詳細はfeatures配下へ委譲する。
import PatientWorkspace from './features/patients/components/PatientWorkspace.vue'
import PatientSearchWorkspace from './features/patients/components/PatientSearchWorkspace.vue'
import DepartmentWorkspace from './features/administration/departments/components/DepartmentWorkspace.vue'
import OccupationWorkspace from './features/administration/occupations/components/OccupationWorkspace.vue'
import SqlConsole from './features/development/components/SqlConsole.vue'
import OutpatientListWorkspace from './features/outpatients/components/OutpatientListWorkspace.vue'
import ReceptionWorkspace from './features/receptions/components/ReceptionWorkspace.vue'
import ReservationWorkspace from './features/reservations/components/ReservationWorkspace.vue'
import OutpatientWorkflowDialog from './features/outpatients/components/OutpatientWorkflowDialog.vue'
const outpatientList = location.pathname === '/outpatients'
const sqlConsole = location.pathname === '/tools/sql'
const departmentMaster = location.pathname === '/masters/departments'
const occupationMaster = location.pathname === '/masters/occupations'
const patientSearch = location.pathname === '/patients'
const receptionWorkspace = location.pathname === '/receptions/new'
const reservationWorkspace = location.pathname === '/reservations/new'
</script>

<template>
  <OutpatientListWorkspace v-if="outpatientList" />
  <SqlConsole v-else-if="sqlConsole" />
  <DepartmentWorkspace v-else-if="departmentMaster" />
  <OccupationWorkspace v-else-if="occupationMaster" />
  <ReceptionWorkspace v-else-if="receptionWorkspace" />
  <OutpatientWorkflowDialog v-else-if="reservationWorkspace" mode="予約"><ReservationWorkspace /></OutpatientWorkflowDialog>
  <PatientSearchWorkspace v-else-if="patientSearch" />
  <PatientWorkspace v-else-if="!outpatientList" />
</template>
