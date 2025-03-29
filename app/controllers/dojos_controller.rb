class DojosController < ApplicationController

  # GET /dojos[.json]
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
      # No corresponding View for now.
      # Only for API: GET /dojos.json
      format.html { redirect_to root_url(anchor: 'dojos') }
      format.json { render json: @dojo_data }
    end
  end

  # GET /dojos/:id
  def show
    @dojo = Dojo.find(params[:id])
    @event_histories = @dojo.event_histories.order(:evented_at)

    respond_to do |format|
      format.html
      format.json { render json: @event_histories }
    end
  end
end
