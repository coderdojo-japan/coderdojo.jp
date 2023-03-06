class UpcomingEvent < ApplicationRecord
  belongs_to :dojo_event_service

  validates :service_name, presence: true, uniqueness: { scope: :event_id  }
  validates :event_id,     presence: true
  validates :event_url,    presence: true
  validates :event_at,     presence: true
  validates :participants, presence: true
  validates :event_end_at, presence: true

  scope :for,   ->(service) { where(dojo_event_service: DojoEventService.for(service)) }
  scope :since, ->(date)    { where('event_end_at >= ?', date.beginning_of_day) }
  scope :until, ->(date)    { where('event_end_at < ?',  date.beginning_of_day) }

  class << self
    def group_by_prefecture
      events_by_prefecture = eager_load(dojo_event_service: :dojo)
        .since(Time.zone.today)
        .merge(Dojo.default_order)
        .group_by { |event| event.dojo_event_service.dojo.prefecture_id }

      result = {}
      Prefecture.order(:id).each do |prefecture|
        events = events_by_prefecture[prefecture.id]
        next if events.blank?
        result[prefecture.name] = events.sort_by(&:event_at).map(&:catalog)
      end

      result
    end

    def group_by_keyword(keyword)
      eager_load(dojo_event_service: :dojo).since(Time.zone.today).
        merge(Dojo.default_order).
        where('event_title like(?)', "%#{keyword}%")
    end

    def for_dojo_map
      result = []
      dojos_and_events = eager_load(dojo_event_service: :dojo)
        .since(Time.zone.today)
        .merge(Dojo.default_order)
        .group_by { |event| event.dojo_event_service.dojo }

      dojos_and_events.each do |dojo, events|
        event = events.sort_by(&:event_at).first
        result << {
          id:   dojo.id,
          name: dojo.name,
          url:  dojo.url,
          event_title: event[:event_title],
          event_date:  event[:event_at],
          event_url:   event[:event_url],
        }
      end

      result
    end
  end

  def catalog
    # NOTE: 奈良・生駒・平群などの Dojo 名は特別に加工
    dojo_name = if dojo_event_service.name == 'connpass' && dojo_event_service.group_id == '2617'
                  '奈良・生駒・平群'
                elsif dojo_event_service.name == 'connpass' && dojo_event_service.group_id == '8204'
                  '昭島・たまみら'
                else
                  dojo_event_service.dojo.name
                end
    {
      dojo_name:            dojo_name,
      dojo_prefecture_name: dojo_event_service.dojo.prefecture.name,
      event_title:          event_title,
      event_url:            event_url,
      event_at:             event_at,
      event_date:           event_at.to_date
    }
  end
end
