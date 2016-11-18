class CoderDojo < ActiveRecord::Base
  validates :name,            presence: true, length: { maximum: 50 }
  validates :course,          presence: true, length: { maximum: 25 }
  validates :caption,         presence: true, length: { maximum: 60 }
  validates :venue,           presence: true
  validates :region,          presence: true
  validates :logo_image_url,  presence: true
  validates :redirect_url,    presence: true
  validates :user_name,       presence: true, length: { maximum: 50 }
  validates :email,           presence: true, length: { maximum: 255 }
end