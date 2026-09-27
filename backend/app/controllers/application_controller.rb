# 全API Controllerの共通親。継承先へCSRF検証、no-storeヘッダー、既知の例外のJSON応答を適用する。
# CSRF対策はログイン機能ではなく、ローカル限定という利用条件は変えない。
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # Railsが各actionの前に実行し、患者情報を含む応答をブラウザへ保存させない。
  before_action { response.set_header("Cache-Control", "no-store") }
  # rescue_fromは各actionで処理されない例外を捕捉し、API用HTTPステータスとJSONへ変換する。
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
