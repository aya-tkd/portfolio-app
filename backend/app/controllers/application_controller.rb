# 全Controllerの共通処理。CSRF検証と既知の例外のJSON化を担当する。
# CSRF対策はログイン機能ではなく、ローカル限定という利用条件は変えない。
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action { response.set_header("Cache-Control", "no-store") }
  rescue_from ActiveRecord::RecordNotFound do
    render json: { message: "患者が見つかりません。" }, status: :not_found
  end
  rescue_from ActionController::InvalidAuthenticityToken do
    render json: { message: "画面を再読み込みしてから操作してください。" }, status: :forbidden
  end
  rescue_from ActionController::ParameterMissing do
    render json: { message: "入力形式が不正です。" }, status: :bad_request
  end
end
