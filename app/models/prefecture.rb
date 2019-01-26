class Prefecture < ApplicationRecord
  default_scope -> { order(id: :asc) }
  validates :name,   presence: true, uniqueness: true
  validates :region, presence: true
end
