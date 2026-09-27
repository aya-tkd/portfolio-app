module Api
  # スタッフ基本情報の検索・参照・保存を受け付けるAPI。認証情報は受け取らず、画面に必要なJSONだけを返す。
  class UsersController < ApplicationController
    FIELDS = %i[id last_name first_name last_name_kana first_name_kana department_id occupation_id active].freeze
    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "ユーザーが見つかりません。" }, status: :not_found
    end

    # 検索条件に一致するユーザーと関連マスタ名を一覧JSONで返す。
    def index
      users = User.search(**search_params.to_h.symbolize_keys)
      render json: users.map { |user| present(user) }
    end

    # 内部IDでユーザーと診療科・職種を読み込み、編集フォーム用JSONを返す。
    def show
      render json: present(User.includes(:department, :occupation).find(params[:id]))
    end

    # 許可済み入力からスタッフ情報を作成し、保存結果を返す。
    def create
      persist(User.new(user_params), :created)
    end

    # 内部IDのスタッフ情報を更新し、保存結果を返す。
    def update
      user = User.find(params[:id])
      user.assign_attributes(user_params)
      persist(user, :ok)
    end

    private

    # URL queryからユーザーID・氏名・関連マスタの検索項目だけを取得する。
    def search_params
      params.permit(:user_id, :name, :department_id, :occupation_id)
    end

    # Strong Parametersでユーザー登録・更新に許可する項目を限定する。
    def user_params
      params.expect(user: [*User::NAME_FIELDS, :department_id, :occupation_id, :active])
    end

    # Active Recordの保存結果を作成・更新のHTTP応答へ共通変換する。
    def persist(user, status)
      if user.save
        render json: present(user), status:
      else
        render json: { errors: user.errors.to_hash }, status: :unprocessable_content
      end
    end

    # 関連IDに加えて一覧表示に必要な診療科名・職種名をJSONへ含める。
    def present(user)
      user.as_json(only: FIELDS).merge(department_name: user.department&.name, occupation_name: user.occupation&.name)
    end
  end
end
