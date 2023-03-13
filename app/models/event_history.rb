class EventHistory < ApplicationRecord
  belongs_to :dojo

  validates :dojo_name,    presence: true
  validates :service_name, presence: true, uniqueness: { scope: :event_id  }
  validates :event_id,     presence: true
  validates :event_url,    presence: true, uniqueness: true, allow_nil: true
  validates :participants, presence: true
  validates :evented_at,   presence: true

  scope :for,   ->(service) { where(service_name: service) }
  scope :within, ->(period) { where(evented_at: period) }

  class << self
    def annual_count(period)
      Hash[
        where(evented_at: period)
          .group('year')
          .order('year ASC')
          .pluck(Arel.sql("to_char(evented_at, 'yyyy') AS year, COUNT(id)"))
      ]
    end

    def annual_sum_of_participants(period)
      Hash[
        where(evented_at: period)
          .group('year')
          .order('year ASC')
          .pluck(Arel.sql("to_char(evented_at, 'yyyy') AS year, SUM(participants)"))
      ]
    end
  end
end
