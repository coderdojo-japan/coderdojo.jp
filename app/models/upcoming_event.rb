class UpcomingEvent < ApplicationRecord
  belongs_to :dojo_event_service

  validates :service_name, presence: true, uniqueness: { scope: :event_id  }
  validates :event_id,     presence: true
  validates :event_url,    presence: true
  validates :event_at,     presence: true
  validates :participants, presence: true

  scope :for, ->(service) { where(dojo_event_service: DojoEventService.for(service)) }
  scope :since, ->(date) { where('event_at >= ?', date.beginning_of_day) }
  scope :until, ->(date) { where('event_at < ?', date.beginning_of_day) }

  class << self
    def group_by_date
      eager_load(dojo_event_service: { dojo: :prefecture }).since(Time.zone.today).
        order(:event_at).map(&:catalog).group_by { |d| d[:event_date] }
    end
  end

  def catalog
    {
      dojo_name:            dojo_event_service.dojo.name,
      dojo_prefecture_name: dojo_event_service.dojo.prefecture.name,
      event_title:          event_title,
      event_url:            event_url,
      event_at:             event_at,
      event_date:           event_at.to_date
    }
  end
end
