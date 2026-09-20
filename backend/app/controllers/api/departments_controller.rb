module Api
  # routes.rbが診療科APIのHTTP要求に応じて呼ぶ窓口。
  # 許可した入力だけをDepartmentへ渡し、保存・取得結果または項目別エラーをJSONでVueへ返す。
  class DepartmentsController < ApplicationController
    FIELDS = %i[id name kana_name abbreviation display_order active].freeze

    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "診療科が見つかりません。" }, status: :not_found
    end

    # マスタ設定の一覧領域から呼ばれる検索API。文字列は部分一致、利用状態は任意の絞り込みにする。
    # GET /api/departments?keyword=<名称・カナ名>&active=true|false
    def index
      departments = Department.order(:display_order, :id)
      keyword = params[:keyword].to_s.strip
      if keyword.present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%"
        departments = departments.where("name LIKE ? OR kana_name LIKE ?", pattern, pattern)
      end
      departments = departments.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
      render json: departments.as_json(only: FIELDS)
    end

    def show
      render json: Department.find(params[:id]).as_json(only: FIELDS)
    end

    def create
      persist Department.new(department_params), :created
    end

    def update
      department = Department.find(params[:id])
      department.assign_attributes(department_params)
      persist department, :ok
    end

    private

    def department_params
      # ブラウザから改変して送られても、DBが自動採番する内部IDは更新対象に含めない。
      params.expect(department: %i[name kana_name abbreviation display_order active])
    end

    def persist(department, status)
      if department.save
        render json: department.as_json(only: FIELDS), status: status
      else
        render json: { errors: department.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
