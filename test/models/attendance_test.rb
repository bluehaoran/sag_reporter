require "test_helper"

describe Attendance do

  let (:john) { Person.create name: "John", geo_state: create(:geo_state) }
  let (:my_event) {
    Event.new event_label: "label",
    event_date: Date.today,
    geo_state: create(:geo_state),
    participant_amount: 15,
    sub_district: sub_districts(:falakata),
		user_id: users(:andrew).id 
  }
  let (:attendance) { Attendance.new person: john, event: my_event}

  # it "must be valid" do
  #   value(attendance).must_be :valid?
  # end
  #
  # it "wont be valid without a person" do
  #   attendance.person = nil
  #   attendance.valid?
  #   value(attendance.errors[:person]).must_be :any?
  # end
  #
  # it "wont be valid without an event" do
  #   attendance.event = nil
  #   attendance.valid?
  #   value(attendance.errors[:event]).must_be :any?
  # end
  #
  # it "must be unique" do
  #   attendance2 = attendance.dup
  #   attendance.save
  #   attendance2.wont_be :valid?
  # end

end
