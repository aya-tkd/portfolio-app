require "test_helper"

# HTTPを介さずModelとDBの制約を検証する。各テストのDB変更はRailsがロールバックする。
class PatientTest < ActiveSupport::TestCase
  test "AC-01 persists separate unique display number and nullable birthday" do
    patient = Patient.create!(patient_attributes)
    assert_equal patient.id.to_s, patient.reload.patient_number
    assert_nil patient.birth_date
    assert_raises(ActiveRecord::RecordNotUnique) do
      Patient.insert_all!([{ **patient_attributes, patient_number: patient.patient_number, created_at: Time.current, updated_at: Time.current }])
    end
  end

  test "AC-02 identity is readonly and birthday can be cleared" do
    patient = Patient.create!(patient_attributes.merge(birth_date: "1990-01-01"))
    assert_raises(ActiveRecord::ReadonlyAttributeError) { patient.patient_number = "another" }
    assert_raises(ActiveRecord::ReadonlyAttributeError) { patient.id = 98765 }
    patient.update!(birth_date: nil, first_name: "次郎")
    assert_nil patient.reload.birth_date
    assert_equal "次郎", patient.first_name
  end

  test "AC-03 required names and 100 character boundary" do
    Patient::NAME_FIELDS.each do |field|
      ["", "　 "].each { |value| assert_not Patient.new(patient_attributes.merge(field => value)).valid? }
      assert Patient.new(patient_attributes.merge(field => "ア" * 100)).valid?
      assert_not Patient.new(patient_attributes.merge(field => "ア" * 101)).valid?
    end
  end

  test "AC-03 kana and sex values" do
    assert Patient.new(patient_attributes.merge(last_name_kana: "デモ・カンジャー　ア")).valid?
    %w[かな ｶﾅ abc].each { |value| assert_not Patient.new(patient_attributes.merge(first_name_kana: value)).valid? }
    ["", "male", "female", "other"].each { |sex| assert Patient.new(patient_attributes.merge(sex: sex)).valid? }
    assert_not Patient.new(patient_attributes.merge(sex: "unknown")).valid?
  end

  test "AC-03 dates are strict and optional" do
    [nil, "", "2000-02-29", Date.current.iso8601].each do |date|
      assert Patient.new(patient_attributes.merge(birth_date: date)).valid?, date.inspect
    end
    ["2025-02-29", "not-a-date", "2020-1-1", Date.tomorrow.iso8601].each do |date|
      assert_not Patient.new(patient_attributes.merge(birth_date: date)).valid?, date.inspect
    end
  end

  test "AC-01 numbering collision rolls back the whole create" do
    patient = Patient.create!(patient_attributes)
    next_id = patient.id + 1
    Patient.where(id: patient.id).update_all(patient_number: next_id.to_s)
    assert_no_difference "Patient.count" do
      assert_raises(ActiveRecord::RecordNotUnique) { Patient.create!(patient_attributes) }
    end
  end
end
