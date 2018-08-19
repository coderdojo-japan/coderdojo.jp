class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES    = "100"
  NUM_OF_WHOLE_DOJOS  = "1,900"
  YAML_FILE           = Rails.root.join('db', 'dojos.yaml')

  belongs_to :prefecture
  has_many   :dojo_event_services, dependent: :destroy
  has_many   :event_histories,     dependent: :destroy

  serialize :tags
  before_save { self.email = self.email.downcase }

  scope :default_order, -> { order(prefecture_id: :asc, order: :asc) }
  scope :active, -> { where(is_active: true) }

  validates :name,        presence: true, length: { maximum: 50 }
  validates :email,       presence: false
  validates :order,       presence: false
  validates :description, presence: true, length: { maximum: 50 }
  validates :logo,        presence: false
  validates :tags,        presence: true
  validate  :number_of_tags
  validates :url,         presence: true

  class << self
    def load_attributes_from_yaml
      YAML.load_file(YAML_FILE)
    end

    def dump_attributes_to_yaml(attributes)
      YAML.dump(attributes, File.open(YAML_FILE, 'w'))
    end

    def active_dojos_count
      active.count
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
          .pluck("to_char(dojos.created_at, 'yyyy') AS year, COUNT(DISTINCT dojos.id)")
      ]
    end

    def annual_count(period)
      Hash[
        where(created_at: period)
          .group('year')
          .order('year ASC')
          .pluck("to_char(created_at, 'yyyy') AS year, COUNT(id)")
      ]
    end
  end

  private

  def number_of_tags
    num_of_tags = self.tags.length
    if num_of_tags > 5
      errors.add(:number_of_tags, 'should be 1 to 5')
    end
  end
end
