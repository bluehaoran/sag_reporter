class Observation < ActiveRecord::Base
  belongs_to :report, inverse_of: :observations, touch: true
  belongs_to :person, inverse_of: :observations
  validates :report, presence: true, uniqueness: { scope: :person }
  validates :person, presence: true
end
