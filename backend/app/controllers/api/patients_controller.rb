module Api
  class PatientsController < ApplicationController
    # routes.rbがHTTPメソッドとURLに応じて呼ぶAPI窓口。
    # 許可した入力だけをModelへ渡し、保存結果か項目別エラーをJSONでVueへ返す。
    FIELDS = %i[id patient_number last_name first_name last_name_kana first_name_kana birth_date sex].freeze

    def csrf
      render json: { token: form_authenticity_token }
    end

    # 患者検索画面の読取専用API。URLクエリの条件をModelへ渡し、画面に必要な列だけをJSONで返す。
    # GET /api/patients?patient_number=<完全一致>&name=<部分一致> をroutes.rbがここへ振り分ける。
    def index
      patients = Patient.search(patient_number: search_params[:patient_number], name: search_params[:name])
      render json: patients.as_json(only: FIELDS)
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

    def search_params
      # 検索条件は許可した二項目だけを受け取り、SQL文字列をControllerで組み立てない。
      params.permit(:patient_number, :name)
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
