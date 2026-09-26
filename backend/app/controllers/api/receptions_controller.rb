module Api
  # 患者検索後の受付候補取得と受付登録を受け持つHTTP入口である。
  # VueからのJSONを最小限に検証し、候補Queryまたは業務Serviceへ渡して結果DTOだけを返す。
  class ReceptionsController < ApplicationController
    rescue_from Reception::Register::InvalidTarget do |error|
      render json: { message: error.message }, status: :unprocessable_content
    end
    rescue_from ActiveRecord::RecordInvalid do |error|
      render json: { message: error.record.errors.full_messages.first || "受付を登録できません。" }, status: :unprocessable_content
    end

    # 患者・当日予約・有効な診療科と医師を受付画面の初期データとして返す。
    def reception_candidates
      patient = Patient.find(params[:id])
      render json: {
        patient: patient.as_json(only: PatientsController::FIELDS),
        appointments: Reception::CandidatesQuery.call(patient: patient),
        departments: active_departments.as_json(only: %i[id name]),
        # Vueが受付行ごとの診療科で候補を絞れるよう、担当診療科IDも返す。
        # 候補表示とは別に、保存時はReception::RegisterがDB上で同じ条件を検証する。
        doctor_users: User.active_physicians.map { |user| { id: user.id, name: user.display_name, department_id: user.department_id } }
      }
    end

    # 選択された予約／予約なし受付を受け、全件登録を業務Serviceへ委譲する。
    def create
      input = params.require(:reception).permit(:patient_id, targets: %i[type appointment_id department_id doctor_user_id])
      patient = Patient.find(input.fetch(:patient_id))
      receptions = Reception::Register.call(patient: patient, targets: input.fetch(:targets))
      render json: { receptions: receptions.map { |record| response_item(record) } }, status: :created
    end

    private

    # 登録した受付を、画面の完了通知に必要な項目へ絞って返す。
    def response_item(record)
      { id: record.id, reception_number: record.reception_number, department_name: record.department.name }
    end

    # 有効な診療科を表示順で取得し、過去デモデータの同名候補をまとめる。
    def active_departments
      # 既存のローカル試験データに同名診療科があっても、受付候補は診療科名ごとに一つだけ表示する。
      # 新規の重複はDepartmentの一意性検証で防ぎ、過去データの整理は別Issueで扱う。
      Department.where(active: true).order(:display_order, :id).to_a.uniq(&:name)
    end
  end
end
