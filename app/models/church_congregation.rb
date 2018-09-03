class ChurchCongregation < ActiveRecord::Base
  belongs_to :organisation
  has_many :users, dependent: :nullify
  has_many :planned_ministries, dependent: :destroy
  has_many :actual_ministries, dependent: :destroy

  validates :village, presence: true, uniqueness: { scope: :organisation }

  def full_name
    description = "#{organisation ? organisation.name : 'independent church'} in #{village}"
    name.present? ? "#{name} (#{description})" : description
  end
end