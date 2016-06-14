class CoderDojo < ActiveRecord::Base
  validates :name, presence: true
end
