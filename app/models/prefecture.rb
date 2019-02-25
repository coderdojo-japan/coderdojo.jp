class Prefecture < ApplicationRecord
  validates :name,   presence: true, uniqueness: true
  validates :region, presence: true
end
