class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES   = "70"
  NUM_OF_WHOLE_DOJOS = "1,200"
  NUM_OF_JAPAN_DOJOS = "70"
  UPDATED_DATE       = "2017年1月"

  serialize :tags
  default_scope -> { order(order: :asc) }
  before_save { self.email = self.email.downcase }

  validates :name,        presence: true, length: { maximum: 50 }
  validates :email,       presence: false
  validates :order,       presence: false
  validates :description, presence: true, length: { maximum: 50 }
  validates :logo,        presence: false
  validates :tags,        presence: true
  validates :url,         presence: true

end
