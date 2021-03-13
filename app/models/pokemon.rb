class Pokemon < ApplicationRecord
  validates :email,            presence: true
  validates :parent_name,      presence: true
  validates :participant_name, presence: true
  validates :dojo_name,        presence: true
  validates :download_key,     presence: true

  EXPIRATION_MINUTES = 60

  def download_key_expired?
    self.created_at < Pokemon::EXPIRATION_MINUTES.minutes.ago
  end
end
