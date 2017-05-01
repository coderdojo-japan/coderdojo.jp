class Dojo < ApplicationRecord
  NUM_OF_COUNTRIES   = "70"
  NUM_OF_WHOLE_DOJOS = "1,200"
  NUM_OF_JAPAN_DOJOS = "81"
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
  validate  :number_of_tags
  validates :url,         presence: true

  def self.valid_yaml_format?(path_to_file)
    !!YAML.load_file(path_to_file)
  rescue Exception => e
    #STDERR.puts e.message
    return false
  end

  private

  def number_of_tags
    num_of_tags = self.tags.length
    if num_of_tags > 5
      errors.add(:number_of_tags, 'should be 1 to 5')
    end
  end
end
