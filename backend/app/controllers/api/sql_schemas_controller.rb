module Api
  # 開発用のテーブル一覧/列情報を返すHTTP窓口。DB内容の更新は行わない。
  class SqlSchemasController < ApplicationController
    def show
      return head :not_found unless Rails.env.development? || Rails.env.test?
      render json: Development::SqlSchema.new.call(params[:table])
    rescue ActiveRecord::RecordNotFound
      render json: { message: "テーブルが見つかりません。" }, status: :not_found
    end
  end
end
