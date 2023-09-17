class DojosController < ApplicationController
  def index
    @dojo_data = []
    Dojo.order(order: :asc).all.each do |dojo|
      @dojo_data << {
        id:          dojo.id,
        url:         dojo.url,
        name:        dojo.name,
        logo:        "https://coderdojo.jp#{dojo.logo}",
        order:       dojo.order,
        counter:     dojo.counter,
        is_active:   dojo.is_active,
        prefecture:  dojo.prefecture.name,
        created_at:  dojo.created_at,
        description: dojo.description,
      }
    end

    respond_to do |format|
      format.json  { render json: @dojo_data }

      # No corresponding View for now.
      # Only for API: GET /dojos.json
      format.html { redirect_to root_url(anchor: 'dojos') }
    end
  end

  def recent
    @url = request.url
    @latest_event_by_dojos = []
    Dojo.active.each do |dojo|
      if dojo.event_histories.empty?
        @latest_event_by_dojos << {
          name: dojo.name,
          url:  dojo.url,
          event_at: '2000-01-23',
          event_url: nil
        }
      else
        @latest_event_by_dojos << {
          name: dojo.name,
          url:  dojo.url,
          event_at:  dojo.event_histories.last.evented_at.strftime("%Y-%m-%d"),
          event_url: dojo.event_histories.last.event_url.include?('dummy.url') ?
            "https://www.facebook.com/#{dojo.event_histories.last.service_group_id}/events" :
            dojo.event_histories.last.event_url
        }
      end
    end

    @latest_event_by_dojos.sort_by!{|dojo| dojo[:event_at]}
  end
end
