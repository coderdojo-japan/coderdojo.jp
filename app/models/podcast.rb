class Podcast < ApplicationRecord
  self.table_name = 'podcasts'
  DIR_PATH        = 'public/podcasts'
  WDAY2JAPANESE   = %w(日 月 火 水 木 金 土)
  TIMESTAMP_REGEX  = /-\s((\d{1,2}:)?\d{1,2}:\d{2})/
  YOUTUBE_ID_REGEX = /watch\?v=((\w)*)/

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

  def exist?(offset: 0)
    return false if self.path.include?("\u0000")
    return false if (self.id + offset).zero?
    File.exist?("#{DIR_PATH}/#{id + offset}.md")
  end

  def cover
    cover = Dir.glob("public/podcasts/#{self.id}.{jpg,png}")
    cover.blank? ? nil : cover.first[6..]
  end

  def content
    exist? ? File.read(path) : ''
  end
end
