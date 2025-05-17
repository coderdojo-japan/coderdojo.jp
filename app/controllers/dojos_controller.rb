class DojosController < ApplicationController

  # GET /dojos[.json]
  def index
    @dojos = []
    Dojo.includes(:prefecture).order(order: :asc).all.each do |dojo|
      @dojos << {
        id:          dojo.id,
        url:         dojo.url,
        name:        dojo.name,
        logo:        root_url + dojo.logo[1..],
        order:       dojo.order,
        counter:     dojo.counter,
        is_active:   dojo.is_active,
        prefecture:  dojo.prefecture.name,
        created_at:  dojo.created_at,
        description: dojo.description,
      }
    end

    respond_to do |format|
      # No corresponding View for now.
      # Only for API: GET /dojos.json
      format.html # => app/views/dojos/index.html.erb
      format.json { render json: @dojos }
    end
  end

  # GET /dojos/:id
  def show
    @dojo = Dojo.find(params[:id])
    @event_histories = @dojo.event_histories.order(evented_at: :DESC)
      .select(:evented_at, :participants, :event_url)

    respond_to do |format|
      format.html
      format.json { render json: @event_histories.as_json(except: [:id]) }
      format.csv  { send_data render_to_string, type: :csv }
    end
  end
end
