class News < ApplicationRecord
  scope :recent, -> { order(published_at: :desc) }

  validates :title,        presence: true
  validates :url,          presence: true,
                           uniqueness: true,
                           format: { with: /\Ahttps?:\/\/.*\z/i }
  validates :published_at, presence: true

  def formatted_title
    has_custom_emoji = title[0]&.match?(/[\p{Emoji}&&[^0-9#*]]/)
    return title if has_custom_emoji

    # Add preset Emoji to its prefix if title does not have Emoji.
    emoji = if url.match?(%r{/podcasts/\d+})
              '📻'
            elsif url.match?(%r{prtimes\.jp})
              '📢'
            elsif title.include?('寄贈')
              '🎁'
            else
              '📰'
            end
    "#{emoji} #{title}"
  end

  def link_url
    # Convert absolute podcast URLs to relative paths for local development
    if url.match?(%r{^https://coderdojo\.jp/podcasts/\d+$})
      url.sub('https://coderdojo.jp', '')
    else
      url
    end
  end
end
