class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES    = "75"
  NUM_OF_WHOLE_DOJOS  = "1,500"
  NUM_OF_WHOLE_EVENTS = "1,555"
  NUM_OF_JAPAN_DOJOS = Dojo.count.to_s
  YAML_FILE = Rails.root.join('db', 'dojos.yaml')

  belongs_to :prefecture
  has_many :dojo_event_services, dependent: :destroy
  has_many :event_histories,     dependent: :destroy

  serialize :tags
  before_save { self.email = self.email.downcase }

  scope :default_order, -> { order(prefecture_id: :asc) }

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
  end

  private

  def number_of_tags
    num_of_tags = self.tags.length
    if num_of_tags > 5
      errors.add(:number_of_tags, 'should be 1 to 5')
    end
  end
end
