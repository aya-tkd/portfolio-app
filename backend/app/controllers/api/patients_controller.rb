module Api
  class PatientsController < ApplicationController
    # routes.rbがHTTPメソッドとURLに応じて呼ぶAPI窓口。
    # 許可した入力だけをModelへ渡し、保存結果か項目別エラーをJSONでVueへ返す。
    FIELDS = %i[id patient_number last_name first_name last_name_kana first_name_kana birth_date sex].freeze

    def csrf
      render json: { token: form_authenticity_token }
    end

    def show
      render json: Patient.find(params[:id]).as_json(only: FIELDS)
    end

    def create
      persist Patient.new(patient_params), :created
    end

    def update
      patient = Patient.find(params[:id])
      patient.assign_attributes(patient_params)
      persist patient, :ok
    end

    private

    def patient_params
      # ブラウザから改変して送られても、内部ID・表示Noは更新対象に含めない。
      params.expect(patient: [*Patient::NAME_FIELDS, :birth_date, :sex])
    end

    def persist(patient, status)
      if patient.save
        render json: patient.as_json(only: FIELDS), status: status
      else
        render json: { errors: patient.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
