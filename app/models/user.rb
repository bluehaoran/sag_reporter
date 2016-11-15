class User < ActiveRecord::Base

  include ContactDetails

  belongs_to :role
  has_many :permissions, through: :role
  has_many :reports, foreign_key: 'reporter_id', inverse_of: :reporter
  has_many :events, inverse_of: :record_creator
  has_many :people, inverse_of: :record_creator
  has_many :progress_updates
  has_many :impact_reports, foreign_key: 'reporter_id', inverse_of: :reporter
  belongs_to :mother_tongue, class_name: 'Language', foreign_key: 'mother_tongue_id'
  has_and_belongs_to_many :spoken_languages, class_name: 'Language'
  has_many :tally_updates
  has_and_belongs_to_many :geo_states
  delegate :zone, to: :geo_state, allow_nil: true
  has_many :output_counts
  belongs_to :interface_language, class_name: 'Language', foreign_key: 'interface_language_id'
  has_many :mt_resources
  before_update :send_confirmation_email

  attr_accessor :remember_token

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true, length: { is: 10 }, format: { with: /\A\d+\Z/ }, uniqueness: true
  has_secure_password
  has_one_time_password
  validates :password,
            presence: true,
            length: { minimum: 6 },
            format: {
                with: /\A[\d\w ]+\Z/im,
                message: 'must use only letters, numbers and spaces'
            },
            allow_nil: true
  validates :mother_tongue_id, presence: true, allow_nil: false
  validates :role_id, presence: true, allow_nil: false
  validates :geo_states, presence: true

  # Returns the hash digest of the given string.
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions.
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Pretty print phone number
  def pretty_phone
    self.phone.slice(0..3) + ' ' + self.phone.slice(4..6) + ' ' + self.phone.slice(7..-1)
  end

  # True if this user belongs to all states instead of one
  def in_all_geo_states?
    true unless self.geo_states.length > 0
  end

  # Transitional method
  #TODO: make sure nothing uses this, then remove it
  def geo_state
    geo_states.take
  end

  def zones
    Zone.of_states geo_states
  end

  def email_activate
    self.email_confirmed = true
    self.confirm_token = nil
    save!(:validate => false)
  end


  # allow method names such as is_a_ROLE1_or_ROLE2?
  # where ROLE1 and ROLE2 are the names of a valid roles
  # or can_PERM1_or_PERM2?
  # where PERM1 and PERM2 are the names of a valid permissions
  def method_missing(method_id, *args)
    if match = matches_dynamic_role_check?(method_id)
      tokenize(match.captures.first).each do |role_name|
        return true if role.name.downcase == role_name
      end
      return false
    elsif match = matches_dynamic_perm_check?(method_id)
      tokenize(match.captures.first).each do |perm_name|
         return true if permissions.find_by_name(perm_name)
      end
      return false
    else
      super
    end
  end

  def resend_email_token
    self.confirm_token = SecureRandom.urlsafe_base64.to_s
    save!(:validate => false)
  end


      private

      def tokenize(string_to_split)
        string_to_split.split(/_or_/)
      end

      def matches_dynamic_role_check?(method_id)
        /^is_an?_([a-zA-Z]\w*)\?$/.match(method_id.to_s)
      end

      def matches_dynamic_perm_check?(method_id)
        /^can_([a-zA-Z]\w*)\?$/.match(method_id.to_s)
      end

      def send_confirmation_email
        if self.confirm_token.blank? && self.email_changed?
          self.confirm_token = SecureRandom.urlsafe_base64.to_s
          UserMailer.user_email_confirmation(self).deliver_now
        end
      end
end
