class Podcast < ApplicationRecord
  self.table_name = 'podcasts'

  DIR_PATH  = 'public/podcasts'

  validates :track_id,              presence: true, uniqueness: true
  validates :title,                 presence: true
  validates :original_content_size, presence: true
  validates :duration,              presence: true
  validates :download_url,          presence: true
  validates :permalink,             presence: true
  validates :permalink_url,         presence: true
  validates :uploaded_at,           presence: true
  validates :published_date,        presence: true

  # instance methods
  def path
    "#{DIR_PATH}/#{id}.md"
  end

  def exists?(offset: 0)
    return false if path.include?("\u0000")
    File.exists?("#{DIR_PATH}/#{id + offset}.md")
  end

  def content
    exists? ? File.read(path) : ''
  end
end
