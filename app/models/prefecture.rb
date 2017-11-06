class Prefecture < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :region, presence: true

  def self.regions
    self.order(:id).pluck(:region).uniq
  end
end
