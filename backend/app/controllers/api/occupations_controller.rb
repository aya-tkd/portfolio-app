module Api
  # 職種APIのHTTP窓口。許可した入力だけをOccupationへ渡し、結果または項目別エラーをJSONで返す。
  class OccupationsController < ApplicationController
    FIELDS = %i[id name display_order active].freeze

    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "職種が見つかりません。" }, status: :not_found
    end

    def show
      render json: Occupation.find(params[:id]).as_json(only: FIELDS)
    end

    def create
      persist Occupation.new(occupation_params), :created
    end

    def update
      occupation = Occupation.find(params[:id])
      occupation.assign_attributes(occupation_params)
      persist occupation, :ok
    end

    private

    def occupation_params
      # 自動採番IDはブラウザから更新できない。
      params.expect(occupation: %i[name display_order active])
    end

    def persist(occupation, status)
      if occupation.save
        render json: occupation.as_json(only: FIELDS), status: status
      else
        render json: { errors: occupation.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
