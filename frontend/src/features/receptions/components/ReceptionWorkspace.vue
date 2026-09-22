<script setup>
// 患者検索から遷移する受付登録画面。受付対象と担当医ユーザーの選択状態を管理する。
// API呼出は receptions/api.js に集約し、登録成功時だけ外来一覧へ遷移する。
import { computed, onMounted, ref } from "vue";
import PatientBanner from "../../../shared/components/PatientBanner.vue";
import { loadReceptionCandidates, registerReceptions } from "../api.js";

const props = defineProps({
  modal: { type: Boolean, default: false },
  patientId: { type: [String, Number], default: null },
});
const emit = defineEmits(["completed", "cancelled"]);
const patient = ref(null),
  appointments = ref([]),
  departments = ref([]),
  doctors = ref([]);
const selectedIds = ref([]),
  doctorSelections = ref({}),
  unreserved = ref([]);
const loading = ref(true),
  saving = ref(false),
  message = ref(""),
  error = ref(false),
  results = ref([]);
const patientId = computed(
  () =>
    props.patientId || new URLSearchParams(location.search).get("patient_id"),
);
const selectedAppointments = computed(() =>
  appointments.value.filter((item) => selectedIds.value.includes(item.id)),
);
const receptionCount = computed(
  () => selectedAppointments.value.length + unreserved.value.length,
);
const needsDoctor = computed(
  () =>
    selectedAppointments.value.some((item) => item.kind === "consultation") ||
    unreserved.value.length > 0,
);
const doctorFor = (item) => doctorSelections.value[item.id] || "";
// 候補APIは全有効医師を返し、各受付行の診療科に対してVue側で選択肢を絞る。
// 担当診療科が未設定の医師は、どの診療科の受付でも候補に含める。
const doctorsForDepartment = (departmentId) =>
  doctors.value.filter(
    (doctor) =>
      doctor.department_id === null ||
      String(doctor.department_id) === String(departmentId),
  );
const hasEligibleDoctor = (departmentId) =>
  doctorsForDepartment(departmentId).length > 0;
function resetIneligibleDoctor(item) {
  if (
    !doctorsForDepartment(item.department_id).some(
      (doctor) => String(doctor.id) === String(item.doctor_user_id),
    )
  ) {
    item.doctor_user_id = "";
  }
}
const hasIncompleteDoctor = computed(
  () =>
    selectedAppointments.value.some(
      (item) => item.kind === "consultation" && !doctorFor(item),
    ) ||
    unreserved.value.some(
      (item) => !item.department_id || !item.doctor_user_id,
    ),
);
const canSubmit = computed(
  () =>
    receptionCount.value > 0 &&
    !hasIncompleteDoctor.value &&
    !results.value.length,
);

function addUnreserved() {
  unreserved.value.push({
    key: crypto.randomUUID(),
    department_id: "",
    doctor_user_id: "",
  });
}
function removeUnreserved(key) {
  unreserved.value = unreserved.value.filter((item) => item.key !== key);
}
function close() {
  if (props.modal) emit("cancelled");
  else window.location.assign("/patients");
}
function goOutpatients() {
  if (props.modal) emit("completed", results.value);
  else window.location.assign("/outpatients");
}

async function load() {
  if (!patientId.value) {
    error.value = true;
    message.value = "患者を選択してから受付を開始してください。";
    loading.value = false;
    return;
  }
  try {
    const data = await loadReceptionCandidates(patientId.value);
    patient.value = data.patient;
    appointments.value = data.appointments;
    departments.value = data.departments;
    doctors.value = data.doctor_users || [];
    doctorSelections.value = Object.fromEntries(
      appointments.value
        .filter((item) => item.kind === "consultation")
        .map((item) => [
          item.id,
          doctorsForDepartment(item.department_id).some(
            (doctor) => String(doctor.id) === String(item.doctor_user_id),
          )
            ? String(item.doctor_user_id)
            : "",
        ]),
    );
  } catch (cause) {
    error.value = true;
    message.value = cause.message || "受付候補を取得できませんでした。";
  } finally {
    loading.value = false;
  }
}

async function submit() {
  if (saving.value || !canSubmit.value) return;
  saving.value = true;
  message.value = "";
  error.value = false;
  const targets = [
    ...selectedAppointments.value.map((item) =>
      item.kind === "consultation"
        ? {
            type: "appointment",
            appointment_id: item.id,
            doctor_user_id: Number(doctorFor(item)),
          }
        : { type: "appointment", appointment_id: item.id },
    ),
    ...unreserved.value.map((item) => ({
      type: "unreserved",
      department_id: Number(item.department_id),
      doctor_user_id: Number(item.doctor_user_id),
    })),
  ];
  try {
    const response = await registerReceptions({
      patient_id: patient.value.id,
      targets,
    });
    results.value = response.receptions;
    message.value = "受付を登録しました。外来一覧で次の業務へ進められます。";
  } catch (cause) {
    error.value = true;
    message.value = cause.message || "受付を登録できませんでした。";
  } finally {
    saving.value = false;
  }
}
onMounted(load);
</script>

<template>
  <main class="reception-workspace">
    <p v-if="patient" class="reception-breadcrumb">
      患者検索　›　患者No. {{ patient.patient_number }}　›　外来受付
    </p>
    <PatientBanner v-if="patient" :patient="patient" />
    <p v-if="loading" class="reception-message" role="status">
      受付候補を読み込んでいます。
    </p>
    <p
      v-else-if="!patient"
      class="reception-message reception-message--error"
      role="alert"
    >
      {{ message }}
    </p>
    <template v-else>
      <p class="reception-instruction">
        <strong>受付対象を選択してください。</strong
        >診察予約は複数選択できます。選択した診察ごとに別の受付No.を発行し、付随する設備予約は同じ受付へ引き継ぎます。
      </p>
      <p
        v-if="message"
        :class="['reception-message', { 'reception-message--error': error }]"
        role="status"
      >
        {{ message }}
      </p>
      <p
        v-if="needsDoctor && !doctors.length"
        class="reception-message reception-message--error"
        role="alert"
      >
        有効な医師ユーザーが登録されていません。ユーザーマスタを確認してください。
      </p>
      <section class="reception-layout">
        <section
          class="reception-panel"
          aria-labelledby="appointment-reception"
        >
          <div class="reception-panel__head">
            <h1 id="appointment-reception">予約から受付</h1>
            <span>選択した予約ごとに受付No.を発番します</span>
          </div>
          <div class="appointment-list">
            <p v-if="!appointments.length" class="empty">
              本日の未受付予約はありません。
            </p>
            <table v-else>
              <colgroup>
                <col class="appointment-col--select" />
                <col class="appointment-col--time" />
                <col class="appointment-col--kind" />
                <col class="appointment-col--department" />
                <col class="appointment-col--doctor" />
              </colgroup>
              <thead>
                <tr>
                  <th>受付</th>
                  <th>時刻</th>
                  <th>種別</th>
                  <th>診療科 / 設備</th>
                  <th>担当医</th>
                </tr>
              </thead>
              <tbody>
                <template v-for="item in appointments" :key="item.id">
                  <tr>
                    <td>
                    <input
                      v-model="selectedIds"
                      type="checkbox"
                      :value="item.id"
                      :aria-label="`${item.department_name}を受付対象に選択`"
                    />
                  </td>
                  <td class="time">
                    {{
                      new Date(item.scheduled_at).toLocaleTimeString("ja-JP", {
                        hour: "2-digit",
                        minute: "2-digit",
                      })
                    }}
                  </td>
                  <td>
                    <span class="kind">{{
                      item.kind === "consultation" ? "診察" : "設備"
                    }}</span>
                  </td>
                  <td>
                    {{
                      item.kind === "equipment"
                        ? `${item.equipment_name}（${item.department_name}）`
                        : item.department_name
                    }}
                  </td>
                  <td>
                    <div
                      v-if="item.kind === 'consultation'"
                      class="doctor-select"
                    >
                      <select
                        v-model="doctorSelections[item.id]"
                        class="form-select"
                        :disabled="
                          !selectedIds.includes(item.id) ||
                          !hasEligibleDoctor(item.department_id)
                        "
                        :aria-label="`${item.department_name}の担当医`"
                      >
                        <option value="">選択してください</option>
                        <option
                          v-for="doctor in doctorsForDepartment(
                            item.department_id,
                          )"
                          :key="doctor.id"
                          :value="String(doctor.id)"
                        >
                          {{ doctor.name }}（ユーザーID {{ doctor.id }}）
                        </option>
                      </select>
                      <small
                        v-if="item.doctor_name && !item.doctor_user_id"
                        class="doctor-hint"
                        >予約時の入力：{{
                          item.doctor_name
                        }}（選び直してください）
                      </small>
                    </div>
                    <span v-else>－</span>
                  </td>
                  </tr>
                  <tr class="appointment-detail">
                    <td></td>
                    <td colspan="4">
                      <span class="appointment-detail__label">付随予約・補足</span>
                      <span>
                        {{
                          item.attached_equipment.length
                            ? item.attached_equipment
                                .map(
                                  (child) =>
                                    `${child.name} ${new Date(child.scheduled_at).toLocaleTimeString("ja-JP", { hour: "2-digit", minute: "2-digit" })}`,
                                )
                                .join(" / ")
                            : item.kind === "equipment"
                              ? "設備のみの予約"
                              : "－"
                        }}
                      </span>
                      <p
                        v-if="
                          selectedIds.includes(item.id) &&
                          item.kind === 'consultation' &&
                          !hasEligibleDoctor(item.department_id)
                        "
                        class="doctor-hint doctor-hint--error appointment-detail__error"
                        role="alert"
                      >
                        この診療科に選択可能な担当医がいません。ユーザーマスタの担当診療科を確認してください。
                      </p>
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>
          </div>
        </section>
        <section class="reception-panel" aria-labelledby="unreserved-reception">
          <div class="reception-panel__head">
            <h1 id="unreserved-reception">予約なし受付</h1>
            <button
              type="button"
              class="btn btn-secondary"
              @click="addUnreserved"
            >
              行を追加
            </button>
          </div>
          <p class="panel-note">
            診療科と担当医を指定して、当日受付を追加します。
          </p>
          <div class="unreserved-list">
            <p v-if="!unreserved.length" class="empty">
              予約なし受付は追加されていません。
            </p>
            <div v-else class="unreserved-grid-header" aria-hidden="true">
              <span>診療科<span class="required">＊</span></span>
              <span>担当医<span class="required">＊</span></span>
              <span></span>
            </div>
            <div
              v-for="item in unreserved"
              :key="item.key"
              class="unreserved-entry"
            >
              <div class="unreserved-row">
                <select
                  v-model="item.department_id"
                  class="form-select"
                  aria-label="診療科"
                  @change="resetIneligibleDoctor(item)"
                >
                  <option value="">選択してください</option>
                  <option
                    v-for="department in departments"
                    :key="department.id"
                    :value="department.id"
                  >
                    {{ department.name }}
                  </option>
                </select>
                <select
                  v-model="item.doctor_user_id"
                  class="form-select"
                  aria-label="担当医"
                  :disabled="
                    !item.department_id ||
                    !hasEligibleDoctor(item.department_id)
                  "
                >
                  <option value="">選択してください</option>
                  <option
                    v-for="doctor in doctorsForDepartment(item.department_id)"
                    :key="doctor.id"
                    :value="String(doctor.id)"
                  >
                    {{ doctor.name }}（ユーザーID {{ doctor.id }}）
                  </option>
                </select>
                <button
                  type="button"
                  class="btn btn-secondary unreserved-row__remove"
                  aria-label="この行を削除"
                  @click="removeUnreserved(item.key)"
                >
                  ×
                </button>
              </div>
              <p
                v-if="item.department_id && !hasEligibleDoctor(item.department_id)"
                class="doctor-hint doctor-hint--error unreserved-entry__error"
                role="alert"
              >
                この診療科に選択可能な担当医がいません。ユーザーマスタの担当診療科を確認してください。
              </p>
            </div>
          </div>
        </section>
      </section>
      <div
        v-if="results.length"
        class="reception-complete"
        role="dialog"
        aria-modal="true"
        aria-label="受付登録結果"
      >
        <section>
          <h2>受付登録が完了しました</h2>
          <p>
            <strong>{{ patient.last_name }} {{ patient.first_name }}</strong>
            さんの受付を登録しました。
          </p>
          <ul>
            <li v-for="item in results" :key="item.id">
              {{ item.department_name }}：受付No. {{ item.reception_number }}
            </li>
          </ul>
          <div class="buttons">
            <button
              type="button"
              class="btn btn-primary"
              @click="goOutpatients"
            >
              OK
            </button>
          </div>
        </section>
      </div>
      <footer class="reception-foot">
        <span
          >受付対象 {{ receptionCount }}件 / 発番予定
          {{ receptionCount }}件</span
        >
        <div class="buttons">
          <button
            type="button"
            class="btn btn-primary"
            :disabled="saving || !canSubmit"
            @click="submit"
          >
            {{ saving ? "登録中…" : "受付" }}</button
          ><button type="button" class="btn btn-secondary" @click="close">
            閉じる
          </button>
        </div>
      </footer>
    </template>
  </main>
</template>

<style scoped>
.reception-workspace {
  box-sizing: border-box;
  display: flex;
  flex: 1;
  flex-direction: column;
  min-height: 0;
  margin: 0;
  max-width: none;
  padding: 14px 20px 0;
}
.reception-breadcrumb {
  margin: 0 0 10px;
  color: #526170;
  font-size: 12px;
}
.reception-instruction {
  margin: 14px 0 10px;
  padding: 9px 12px;
  border-left: 4px solid #496c87;
  background: #f7fafc;
  color: #3f515f;
}
.reception-instruction strong {
  margin-right: 8px;
  color: #263c4d;
}
.reception-message {
  margin: 12px 0;
  padding: 9px 12px;
  border-left: 3px solid #26713c;
  background: #fff;
}
.reception-message--error {
  border-color: #b02a37;
  color: #8d1f2a;
}
.reception-layout {
  display: grid;
  flex: 1;
  min-height: 0;
  grid-template-columns: minmax(0, 1.65fr) minmax(360px, 0.9fr);
  gap: 14px;
  overflow: auto;
}
.reception-panel {
  background: #fff;
  border: 1px solid #aebac4;
}
.reception-panel__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 9px 12px;
  border-bottom: 1px solid #aebac4;
  background: #e5ebf0;
}
.reception-panel__head h1 {
  margin: 0;
  font-size: 15px;
}
.reception-panel__head span,
.panel-note {
  color: #4e5c68;
  font-size: 12px;
}
.panel-note {
  margin: 10px 12px;
}
.appointment-list table {
  width: 100%;
  border-collapse: collapse;
  table-layout: auto;
}
.appointment-col--select {
  width: 42px;
}
.appointment-col--time {
  width: 58px;
}
.appointment-col--kind {
  width: 54px;
}
.appointment-col--department {
  width: 130px;
}
.appointment-col--doctor {
  width: 170px;
}
.appointment-list {
  overflow: auto;
}
.appointment-list th,
.appointment-list td {
  padding: 8px 7px;
  border-bottom: 1px solid #dce3e8;
  text-align: left;
  vertical-align: top;
  white-space: normal;
}
.appointment-list th {
  background: #f4f6f8;
  color: #465563;
  font-size: 12px;
}
.appointment-list input[type="checkbox"] {
  width: 17px;
  height: 17px;
  accent-color: #0b5ed7;
}
.time {
  font-variant-numeric: tabular-nums;
  font-weight: 600;
}
.kind {
  display: inline-block;
  padding: 2px 6px;
  border: 1px solid #9eb0bf;
  border-radius: 2px;
  background: #f5f8fa;
  color: #3d556a;
  font-size: 12px;
}
.doctor-select {
  display: block;
}
.doctor-select select {
  width: 100%;
  min-height: 35px;
  border: 1px solid #98a8b6;
  padding: 3px 6px;
}
.doctor-hint {
  display: block;
  margin-top: 4px;
  color: #59636e;
  white-space: normal;
}
.doctor-hint--error {
  color: #8d1f2a;
}
.appointment-detail td {
  padding-top: 0;
  padding-bottom: 8px;
  border-bottom: 1px solid #dce3e8;
  color: #4e5c68;
  font-size: 12px;
}
.appointment-detail__label {
  display: inline-block;
  min-width: 96px;
  color: #263c4d;
  font-weight: 600;
}
.appointment-detail__error {
  margin: 6px 0 0;
}
.required {
  margin-left: 3px;
  color: #b02a37;
}
.empty {
  margin: 0;
  padding: 16px;
  color: #59636e;
}
.unreserved-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 0 12px 12px;
}
.unreserved-grid-header {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) 28px;
  gap: 8px;
  padding: 0 9px 4px;
  color: #465563;
  font-size: 12px;
}
.unreserved-row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr) 28px;
  gap: 8px;
  align-items: center;
  padding: 9px;
  border: 1px solid #dee2e6;
  background: #f8f9fa;
}
.unreserved-row select {
  width: 100%;
}
.unreserved-row__remove {
  width: 28px;
  min-width: 0;
  height: 28px;
  min-height: 0;
  padding: 0;
  color: #59636e;
  font-size: 20px;
  line-height: 1;
}
.unreserved-entry__error {
  margin: 5px 0 0;
  padding: 0 2px;
}
.reception-foot {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: space-between;
  margin-top: 14px;
  padding: 10px 0;
  border-top: 1px solid #8999a6;
  background: #f1f3f5;
  font-size: 13px;
}
.reception-complete {
  position: fixed;
  z-index: 30;
  display: grid;
  inset: 0;
  place-items: center;
  background: #29323b80;
}
.reception-complete section {
  width: min(480px, calc(100vw - 32px));
  padding: 20px;
  border: 1px solid #7b858f;
  background: #fff;
  box-shadow: 0 6px 20px #0003;
}
.reception-complete h2 {
  margin: 0 0 14px;
  font-size: 18px;
}
.reception-complete ul {
  margin: 12px 0 18px;
  padding-left: 22px;
}
.reception-complete .buttons {
  justify-content: flex-end;
}
@media (max-width: 960px) {
  .reception-workspace {
    padding: 0 10px;
  }
  .reception-layout {
    grid-template-columns: 1fr;
  }
}
@media (max-width: 620px) {
  .reception-foot {
    gap: 8px;
    align-items: flex-end;
  }
  .reception-foot > span {
    max-width: 42%;
  }
}
</style>
