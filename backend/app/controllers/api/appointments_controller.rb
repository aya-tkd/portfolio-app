module Api
  # 患者予約の初期表示と一括登録を受け持つController。
  # VueはこのDTOだけを利用し、親子予約の保存順・定員判定は Reservation::Book に委譲する。
  class AppointmentsController < ApplicationController
    rescue_from Reservation::Book::InvalidBooking do |error|
      render json: { message: error.message }, status: :unprocessable_content
    end
    rescue_from Reservation::Book::Conflict do |error|
      render json: { message: error.message }, status: :conflict
    end
    rescue_from ActiveRecord::RecordInvalid do |error|
      render json: { message: error.record.errors.full_messages.join('、') }, status: :unprocessable_content
    end
    rescue_from ActiveRecord::StatementInvalid do |error|
      raise error unless error.cause.is_a?(SQLite3::BusyException)

      render json: { message: '別の登録処理と競合しました。予約内容と空きを確認してください。' }, status: :conflict
    end

    def reservation_booking
      patient = Patient.find(params[:id])
      render json: {
        patient: patient.as_json(only: PatientsController::FIELDS),
        reservation_slots: booking_slots,
        departments: Department.where(active: true).order(:display_order, :id).map { |department| { id: department.id, name: department.name } },
        doctor_users: User.active_physicians.map { |user| { id: user.id, name: user.display_name, department_id: user.department_id } },
        appointments: existing_appointments(patient)
      }
    end

    def create_bulk
      input = params.require(:reservation).permit(:patient_id, entries: %i[entry_key reservation_slot_id scheduled_at department_id doctor_user_id parent_entry_key])
      patient = Patient.find(input.fetch(:patient_id))
      appointments = Reservation::Book.call(patient:, entries: input.fetch(:entries))
      render json: { appointments: appointments.map { |appointment| present(appointment) } }, status: :created
    end

    private

    def booking_slots
      ReservationSlot.where(active: true).includes(:default_department, :default_doctor_user).order(:slot_group, :display_order, :id).map do |slot|
        { id: slot.id, name: slot.name, slot_group: slot.slot_group, default_department_id: slot.default_department_id,
          default_doctor_user_id: slot.default_doctor_user_id }
      end
    end

    def existing_appointments(patient)
      Appointment.where(patient:, status: "reserved").includes(:department, :doctor_user, :reservation_slot).order(:scheduled_at, :id).map { |appointment| present(appointment) }
    end

    def present(appointment)
      { id: appointment.id, reservation_slot_id: appointment.reservation_slot_id, reservation_slot_name: appointment.reservation_slot&.name,
        scheduled_at: appointment.scheduled_at.iso8601, kind: appointment.appointment_kind, equipment_name: appointment.equipment_name,
        department_id: appointment.department_id, department_name: appointment.department.name, doctor_user_id: appointment.doctor_user_id,
        doctor_name: appointment.doctor_name, parent_appointment_id: appointment.parent_appointment_id, status: appointment.status }
    end
  end
end
