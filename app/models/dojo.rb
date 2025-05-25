class Dojo < ApplicationRecord
  NUM_OF_PARTNERSHIPS  = "25"
  NUM_OF_ANNUAL_EVENTS = "1,200"
  NUM_OF_ANNUAL_NINJAS = "7,000"
  NUM_OF_TOTAL_EVENTS  = "10,000"
  NUM_OF_TOTAL_NINJAS  = "62,000"
  DOJO_INFO_YAML_PATH = Rails.root.join('db', 'dojos.yaml')

  belongs_to :prefecture
  has_many   :dojo_event_services, dependent: :destroy
  has_many   :event_histories,     dependent: :destroy

  serialize :tags, coder: YAML
  before_save { self.email = self.email.downcase }

  scope :default_order, -> { order(prefecture_id: :asc, order: :asc) }
  scope :active,        -> { where(is_active: true ) }
  scope :inactive,      -> { where(is_active: false) }

  validates :name,        presence: true, length: { maximum: 50 }
  validates :email,       presence: false
  validates :order,       presence: false
  validates :description, presence: true, length: { maximum: 50 }
  validates :logo,        presence: false
  validates :tags,        presence: true
  validates :url,         presence: true
  #validate  :number_of_tags

  class << self
    def load_attributes_from_yaml
      YAML.unsafe_load_file(DOJO_INFO_YAML_PATH)
    end

    def dump_attributes_to_yaml(attributes)
      YAML.dump(attributes, File.open(DOJO_INFO_YAML_PATH, 'w'))
    end

    def active_dojos_count
      active.sum(:counter)
    end

    def group_by_region
      eager_load(:prefecture).default_order.group_by { |dojo| dojo.prefecture.region }
    end

    def group_by_region_on_active
      active.group_by_region
    end

    def aggregatable_annual_count(period)
      Hash[
        joins(:dojo_event_services)
          .where(created_at: period)
          .group('year')
          .order('year ASC')
          .pluck(Arel.sql("to_char(dojos.created_at, 'yyyy') AS year, COUNT(DISTINCT dojos.id)"))
      ]
    end

    def annual_count(period)
      Hash[
        where(created_at: period)
          .group('year')
          .order('year ASC')
          .pluck(Arel.sql("to_char(created_at, 'yyyy') AS year, SUM(counter)"))
      ]
    end
  end

  private

  # Now 6+ tags are available since this PR:
  # https://github.com/coderdojo-japan/coderdojo.jp/pull/1697
  #def number_of_tags
  #  num_of_tags = self.tags.length
  #  if num_of_tags > 5
  #    errors.add(:number_of_tags, 'should be 1 to 5')
  #  end
  #end
end
