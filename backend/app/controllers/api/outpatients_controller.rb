module Api
  # 外来画面のHTTP窓口。読取はQuery、進捗更新はServiceへ渡し、結果をJSONで返す。
  # CSRF・同一オリジン保護はApplicationControllerの既存設定を継承する。
  class OutpatientsController < ApplicationController
    rescue_from ArgumentError do
      render json: { message: "検索条件または操作の形式が不正です。" }, status: :bad_request
    end
    rescue_from Outpatient::Advance::Conflict, ActiveRecord::StaleObjectError do
      render json: { message: "状態が変更されています。再検索して確認してください。" }, status: :conflict
    end
    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "対象の受付または設備が見つかりません。" }, status: :not_found
    end

    # 日付・診療科・進捗の条件をQueryへ渡し、一覧行と診療科選択肢を返す。
    def index
      render json: { rows: Outpatient::ListQuery.call(date: params[:date] || Date.current.to_s,
        department_id: params[:department_id], statuses: params.key?(:statuses) ? params[:statuses] : Outpatient::ListQuery::STATUSES),
        # 過去の開発用データに同名の診療科があっても、画面の検索条件には同じ名称を一度だけ表示する。
        # ID は最初に並ぶ候補を返し、一覧の絞り込み条件としてそのまま利用する。
        departments: Department.order(:display_order, :id).to_a.uniq(&:name).map { |department| { id: department.id, name: department.name } },
        today: Date.current.to_s }
    end

    # 画面操作名とversionを受け、状態遷移の可否・保存をServiceへ委譲する。
    def update
      input = params.expect(operation: %i[action version equipment_id])
      render json: Outpatient::Advance.call(id: params[:id], action: input[:action], version: input[:version], equipment_id: input[:equipment_id])
    end
  end
end
