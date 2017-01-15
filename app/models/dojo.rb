# -*- coding: utf-8 -*-
class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES   = "70"
  NUM_OF_WHOLE_DOJOS = "1,200"
  NUM_OF_JAPAN_DOJOS = "70"
  UPDATED_DATE       = "2017年1月"

  serialize :tags
  default_scope -> { order(order: :asc) }
end
