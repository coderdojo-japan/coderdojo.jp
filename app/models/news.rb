class News < ApplicationRecord
    scope :recent, -> { order(published_at: :desc) }

    validates :title,        presence: true
    validates :url,          presence: true,
                            uniqueness: true,
                            format: { with: /\Ahttps?:\/\/.*\z/i }
    validates :published_at, presence: true
end
