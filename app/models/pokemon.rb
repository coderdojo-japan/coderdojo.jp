class Pokemon < ApplicationRecord
  validates :email,            presence: true
  validates :parent_name,      presence: true
  validates :participant_name, presence: true
  validates :dojo_name,        presence: true
  validates :download_key,     presence: true
end
