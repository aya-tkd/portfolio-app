module Api
  # スタッフ基本情報の検索・参照・保存を受け付けるAPI。認証情報は受け取らず、画面に必要なJSONだけを返す。
  class UsersController < ApplicationController
    FIELDS = %i[id last_name first_name last_name_kana first_name_kana department_id occupation_id active].freeze
    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "ユーザーが見つかりません。" }, status: :not_found
    end

    def index
      users = User.search(**search_params.to_h.symbolize_keys)
      render json: users.map { |user| present(user) }
    end

    def show
      render json: present(User.includes(:department, :occupation).find(params[:id]))
    end

    def create
      persist(User.new(user_params), :created)
    end

    def update
      user = User.find(params[:id])
      user.assign_attributes(user_params)
      persist(user, :ok)
    end

    private

    def search_params
      params.permit(:user_id, :name, :department_id, :occupation_id)
    end

    def user_params
      params.expect(user: [*User::NAME_FIELDS, :department_id, :occupation_id, :active])
    end

    def persist(user, status)
      if user.save
        render json: present(user), status:
      else
        render json: { errors: user.errors.to_hash }, status: :unprocessable_content
      end
    end

    def present(user)
      user.as_json(only: FIELDS).merge(department_name: user.department&.name, occupation_name: user.occupation&.name)
    end
  end
end
