class News < ApplicationRecord
  # URL patterns
  URL_ROOT     = %r{\Ahttps://coderdojo\.jp}.freeze
  URL_PODCAST  = %r{coderdojo\.jp/podcasts/\d+}.freeze
  URL_PRTIMES  = %r{prtimes\.jp}.freeze
  URL_NEWS     = %r{news\.coderdojo\.jp}.freeze
  ROOT_DOMAIN  = 'https://coderdojo.jp'.freeze

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
    emoji = if url.match?(URL_PODCAST)
              '📻'
            elsif url.match?(URL_PRTIMES)
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
    if url.match?(URL_PODCAST) && url.match?(URL_ROOT)
      url.sub(ROOT_DOMAIN, '')
    else
      url
    end
  end

  def internal_link?
    # Check if the link is internal (coderdojo.jp domain)
    url.match?(URL_ROOT) || url.start_with?('/')
  end

  def to_type
    # Return the type of news based on URL domain
    case url
    when URL_PODCAST; 'ポッドキャスト'
    when URL_PRTIMES; 'プレスリリース'
    when URL_NEWS;    'お知らせ'
    else
      'ニュース'
    end
  end
end
