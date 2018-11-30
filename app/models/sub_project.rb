class SubProject < ActiveRecord::Base
  belongs_to :project
  has_many :language_streams, dependent: :nullify
  has_many :quarterly_evaluations, dependent: :nullify
  validates :name, presence: true
  validates :project, presence: true, uniqueness: { scope: :name }
end
