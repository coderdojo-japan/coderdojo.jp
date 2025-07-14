class News < ApplicationRecord
    scope :recent, -> { order(published_at: :desc) }
end
