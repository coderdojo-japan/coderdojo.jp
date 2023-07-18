class Podcast < ApplicationRecord
  self.table_name = 'podcasts'
  DIR_PATH        = 'public/podcasts'
  WDAY2JAPANESE   = %w(日 月 火 水 木 金 土)

  validates :title,          presence: true
  validates :content_size,   presence: true
  validates :duration,       presence: true
  validates :permalink,      presence: true
  validates :permalink_url,  presence: true
  validates :enclosure_url,  presence: true
  validates :published_date, presence: true

  # instance methods
  def path
    "#{DIR_PATH}/#{id}.md"
  end

  def exists?(offset: 0)
    return false if path.include?("\u0000")
    File.exists?("#{DIR_PATH}/#{id + offset}.md")
  end

  def cover
    cover = Dir.glob("public/podcasts/#{self.id}.{jpg,png}")
    cover.blank? ? nil : cover.first[6..]
  end

  def content
    exists? ? File.read(path) : ''
  end
end
