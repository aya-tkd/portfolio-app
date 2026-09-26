module Api
  # 予約枠マスタの検索・参照・保存を受け付けるHTTP窓口。画面の入力を分値/曜日maskへ変換し、検証結果をJSONで返す。
  class ReservationSlotsController < ApplicationController
    FIELDS = %i[id name slot_group weekdays_mask valid_from valid_to start_minute end_minute interval_minutes capacity default_department_id default_doctor_user_id display_order active lock_version].freeze

    rescue_from ActiveRecord::RecordNotFound do
      render json: { message: "予約枠が見つかりません。" }, status: :not_found
    end
    rescue_from ActiveRecord::StaleObjectError do
      render json: { message: "他の更新が反映されています。再読み込みしてから操作してください。" }, status: :conflict
    end

    # GET /api/reservation_slots。画面の検索条件だけをANDで適用し、ページングした配列と件数を返す。
    def index
      page, per_page = page_params
      slots = ReservationSlot.includes(:default_department, default_doctor_user: :occupation).order(:display_order, :id)
      keyword = params[:keyword].to_s.strip
      slots = slots.where("mst_reservation_slots.name LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%") if keyword.present?
      slots = slots.where(slot_group: params[:slot_group]) if params[:slot_group].present?
      slots = slots.where(default_department_id: params[:default_department_id]) if params[:default_department_id].present?
      slots = slots.where(active: parse_boolean!(params[:active])) if params.key?(:active)
      total = slots.count
      render json: { items: slots.offset((page - 1) * per_page).limit(per_page).map { |slot| present(slot) }, total:, page:, per_page: }
    rescue ArgumentError
      render json: { message: "検索条件を確認してください。" }, status: :bad_request
    end

    # GET /api/reservation_slots/options。編集フォームに必要な有効診療科・医師だけを返す。
    def options
      departments = Department.where(active: true).order(:display_order, :id)
      doctors = User.active_physicians.includes(:department).map { |user| { id: user.id, name: user.display_name, department_id: user.department_id } }
      render json: { departments: departments.map { |department| { id: department.id, name: department.name } }, doctor_users: doctors }
    end

    # 予約画面の週間表へ、枠の適用対象となる日時ごとの残数を返す。
    def availability
      week_start = Date.iso8601(params.fetch(:week_start))
      raise ArgumentError unless week_start.monday?

      slot = ReservationSlot.find(params[:id])
      # 予約済み件数を日時ごとに一括集計し、各時間枠で定員から差し引く。
      # 枠の曜日・有効期間外は時間候補自体を生成せず、レスポンスにも含めない。
      counts = slot.appointments.where(status: 'reserved', scheduled_at: week_start.beginning_of_day..(week_start + 6).end_of_day).group(:scheduled_at).count
      times = (0..6).flat_map do |offset|
        date = week_start + offset
        next [] unless slot.active? && slot.valid_from <= date && date <= slot.valid_to && slot.weekdays.include?(date.cwday)

        (slot.start_minute...slot.end_minute).step(slot.interval_minutes).map do |minute|
          scheduled_at = Time.zone.local(date.year, date.month, date.day, minute / 60, minute % 60)
          booked = counts.fetch(scheduled_at, 0)
          { scheduled_at: scheduled_at.iso8601, ends_at: (scheduled_at + slot.interval_minutes.minutes).iso8601, capacity: slot.capacity, booked_count: booked, remaining: [slot.capacity - booked, 0].max }
        end
      end
      render json: { reservation_slot_id: slot.id, week_start: week_start.iso8601, times: }
    rescue Date::Error, KeyError, ArgumentError
      render json: { message: "週開始日は月曜日のYYYY-MM-DDで指定してください。" }, status: :bad_request
    end

    # 内部IDの枠と関連マスタ名を読み込み、編集フォーム用JSONを返す。
    def show
      render json: present(ReservationSlot.includes(:default_department, default_doctor_user: :occupation).find(params[:id]))
    end

    # Strong Parametersで許可した項目から枠を作成し、検証結果を返す。
    def create
      # 新規時のlock_versionはDB/Railsが0から管理する。ブラウザは任意値を指定できない。
      persist(ReservationSlot.new(slot_attributes), :created)
    end

    # 編集版番号を受けて枠を更新し、同時編集なら409を返す。
    def update
      if params.dig(:reservation_slot, :lock_version).nil?
        render json: { message: "更新版を指定してください。再読み込みしてから操作してください。" }, status: :bad_request
        return
      end
      slot = ReservationSlot.find(params[:id])
      slot.assign_attributes(slot_attributes(include_lock_version: true))
      persist(slot, :ok)
    end

    private

    # JSON入力を許可項目に絞り、時刻文字列と曜日をDB用の分値・ビット集合に変換する。
    def slot_attributes(include_lock_version: false)
      fields = %i[name slot_group valid_from valid_to start_time end_time interval_minutes capacity default_department_id default_doctor_user_id display_order active]
      fields << :lock_version if include_lock_version
      raw = params.expect(reservation_slot: fields)
      weekdays_mask = ReservationSlot.weekdays_to_mask(params.dig(:reservation_slot, :weekdays))
      raw.merge(weekdays_mask:, start_minute: to_minute(raw.delete(:start_time), allow_24: false), end_minute: to_minute(raw.delete(:end_time), allow_24: true))
    end

    # HH:MMの画面入力を午前0時からの分へ変換し、終了時だけ24:00を許可する。
    def to_minute(value, allow_24:)
      matched = /\A([01]\d|2[0-3]):([0-5]\d)\z/.match(value.to_s)
      return 1440 if allow_24 && value == "24:00"
      return -1 unless matched

      matched[1].to_i * 60 + matched[2].to_i
    end

    # URL queryのページ指定を整数化し、許容範囲を確認する。
    def page_params
      page = Integer(params.fetch(:page, 1))
      per_page = Integer(params.fetch(:per_page, 50))
      raise ArgumentError unless page.positive? && per_page.between?(1, 100)

      [page, per_page]
    end

    # URL queryのtrue/falseだけを真偽値へ変換し、それ以外は入力不正にする。
    def parse_boolean!(value)
      return true if value == "true"
      return false if value == "false"

      raise ArgumentError
    end

    # Modelの保存結果を、JSONの成功応答または画面項目別エラーへ変換する。
    def persist(slot, status)
      if slot.save
        render json: present(slot), status:
      else
        render json: { errors: api_errors(slot.errors.to_hash) }, status: :unprocessable_content
      end
    end

    # 分値・曜日maskの内部形式を、編集フォームが使う表示用JSONへ戻す。
    def present(slot)
      slot.as_json(only: FIELDS).merge(
        weekdays: slot.weekdays,
        start_time: minute_to_time(slot.start_minute),
        end_time: minute_to_time(slot.end_minute),
        default_department_name: slot.default_department&.name,
        default_doctor_name: slot.default_doctor_user&.display_name,
        schedule_editable: slot.schedule_editable?
      )
    end

    # DB内部の分値を、フォーム入力で使うHH:MMへ変換する。
    def minute_to_time(value)
      return "24:00" if value == 1440

      format("%02d:%02d", value / 60, value % 60)
    end

    # DB内部の分値ではなく、画面契約の開始/終了時刻フィールドへ入力形式エラーを対応付ける。
    def api_errors(errors)
      { start_minute: :start_time, end_minute: :end_time }.each do |internal, api_field|
        errors[api_field] = errors.delete(internal) if errors.key?(internal)
      end
      errors
    end
  end
end
