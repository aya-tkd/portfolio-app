# routes.rbから呼ばれ、患者APIのHTTP要求をPatientモデルへつなぐ。
# Strong Parametersで受信項目を限定し、検索・保存結果をJSONとして返す。
module Api
  class PatientsController < ApplicationController
    FIELDS = %i[id patient_number last_name first_name last_name_kana first_name_kana birth_date sex].freeze

    # 保存前のVueが取得するCSRFトークンを返す。検証自体はApplicationControllerが行う。
    def csrf
      render json: { token: form_authenticity_token }
    end

    # 患者検索画面の読取専用API。URLクエリの条件をModelへ渡し、画面に必要な列だけをJSONで返す。
    # GET /api/patients?patient_number=<完全一致>&name=<部分一致> をroutes.rbがここへ振り分ける。
    def index
      patients = Patient.search(patient_number: search_params[:patient_number], name: search_params[:name])
      today = Time.zone.today
      start_at = Time.zone.local(today.year, today.month, today.day)
      reservation_patient_ids = Appointment.where(patient_id: patients.select(:id), status: "reserved", reception_id: nil,
        scheduled_at: start_at...start_at + 1.day).distinct.pluck(:patient_id)
      render json: patients.map { |patient| patient.as_json(only: FIELDS).merge(has_today_reservation: reservation_patient_ids.include?(patient.id)) }
    end

    # 内部IDで患者1件を取得し、編集フォーム用のJSONを返す。
    def show
      render json: Patient.find(params[:id]).as_json(only: FIELDS)
    end

    # 許可済み入力から患者を新規作成し、成功または項目別エラーを返す。
    def create
      persist Patient.new(patient_params), :created
    end

    # 内部IDの既存患者へ許可済み入力を適用し、保存結果を返す。
    def update
      patient = Patient.find(params[:id])
      patient.assign_attributes(patient_params)
      persist patient, :ok
    end

    private

    # ブラウザから届く患者項目をStrong Parametersで許可リストに絞る。
    def patient_params
      # ブラウザから改変して送られても、内部ID・表示Noは更新対象に含めない。
      params.expect(patient: [*Patient::NAME_FIELDS, :birth_date, :sex])
    end

    # URL queryから検索に使う項目だけを取得する。
    def search_params
      # 検索条件は許可した二項目だけを受け取り、SQL文字列をControllerで組み立てない。
      params.permit(:patient_number, :name)
    end

    # Active Recordの保存結果を作成・更新のHTTP応答へ共通変換する。
    def persist(patient, status)
      if patient.save
        render json: patient.as_json(only: FIELDS), status: status
      else
        render json: { errors: patient.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
