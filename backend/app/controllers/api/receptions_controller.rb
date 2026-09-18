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

    def reception_candidates
      patient = Patient.find(params[:id])
      render json: {
        patient: patient.as_json(only: PatientsController::FIELDS),
        appointments: Reception::CandidatesQuery.call(patient: patient),
        departments: Department.where(active: true).order(:display_order, :id).as_json(only: %i[id name])
      }
    end

    def create
      input = params.require(:reception).permit(:patient_id, targets: %i[type appointment_id department_id doctor_name])
      patient = Patient.find(input.fetch(:patient_id))
      receptions = Reception::Register.call(patient: patient, targets: input.fetch(:targets))
      render json: { receptions: receptions.map { |record| response_item(record) } }, status: :created
    end

    private

    def response_item(record)
      { id: record.id, reception_number: record.reception_number, department_name: record.department.name }
    end
  end
end
