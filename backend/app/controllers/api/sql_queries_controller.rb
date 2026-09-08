module Api
  # ローカル開発DBの確認用API。CSRF検証はApplicationControllerから継承する。
  # ブラウザからDBパスを受け取らず、現在のRails環境のDBだけを読み取る。
  class SqlQueriesController < ApplicationController
    def create
      return head :not_found unless Rails.env.development? || Rails.env.test?
      render json: Development::SqlQuery.new.call(params[:sql])
    rescue Development::SqlQuery::InvalidQuery => error
      render json: { message: error.message }, status: :unprocessable_content
    end
  end
end
