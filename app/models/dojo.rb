class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES    = "75"
  NUM_OF_WHOLE_DOJOS  = "1,400"
  NUM_OF_WHOLE_EVENTS = "1,555"
  NUM_OF_JAPAN_DOJOS = Dojo.count.to_s

  belongs_to :prefecture
  has_one  :dojo_event_service, dependent: :destroy
  has_many :event_histories,    dependent: :destroy

  serialize :tags
  default_scope -> { order(order: :asc) }
  before_save { self.email = self.email.downcase }

  validates :name,        presence: true, length: { maximum: 50 }
  validates :email,       presence: false
  validates :order,       presence: false
  validates :description, presence: true, length: { maximum: 50 }
  validates :logo,        presence: false
  validates :tags,        presence: true
  validate  :number_of_tags
  validates :url,         presence: true

  def self.valid_yaml_format?(path_to_file)
    !!YAML.load_file(path_to_file)
  rescue Exception => e
    #STDERR.puts e.message
    return false
  end

  def self.find_by_region(region)
    prefecture_ids = Prefecture.where(region: region).pluck(:id)
    Dojo.where(prefecture_id: prefecture_ids)
  end

  private

  def number_of_tags
    num_of_tags = self.tags.length
    if num_of_tags > 5
      errors.add(:number_of_tags, 'should be 1 to 5')
    end
  end
end
