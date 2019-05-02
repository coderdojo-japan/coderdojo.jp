class SoundCloudTrack < ApplicationRecord
  DIR_PATH  = 'public/podcasts'
  URL_PATH  = 'podcasts'

  validates :track_id,              presence: false, uniqueness: true
  validates :title,                 presence: false
  validate  :description
  validates :original_content_size, presence: false
  validates :duration,              presence: false
  validate  :tag_list
  validates :download_url,          presence: false
  validates :permalink,             presence: false
  validates :permalink_url,         presence: false
  validates :uploaded_at,           presence: false

  # instance methods
  def path
    "#{DIR_PATH}/#{self.id}.md"
  end

  def url
    "/#{URL_PATH}/#{self.id}"
  end

  def exists?(offset: 0)
    return false if path.include?("\u0000")
    File.exists?("#{DIR_PATH}/#{self.id + offset}.md")
  end

  def published_at
    exists? ? Time.parse(self.content.lines.second.gsub(/<.+?>/, '').delete('収録日: ')) : ''
  end

  def content
    exists? ? File.read(path) : ''
  end
end
