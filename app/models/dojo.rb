class Dojo < ActiveRecord::Base
  serialize :tags
  default_scope -> { order(order: :asc) }
end
