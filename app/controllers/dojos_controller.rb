class DojosController < ApplicationController
  def index
    @dojo_data = []
    Dojo.order(id: :asc).all.each do |dojo|
      @dojo_data << {
        id:          dojo.id,
        url:         dojo.url,
        name:        dojo.name,
        logo:        "https://coderdojo.jp#{dojo.logo}",
        order:       dojo.order,
        is_active:   dojo.is_active,
        prefecture:  dojo.prefecture.name,
      }
    end

    respond_to do |format|
      format.json  { render json: @dojo_data }

      # No corresponding View for now.
      # Only for API: GET /dojos.json
      format.html { redirect_to root_url(anchor: 'dojos') }
    end
  end
end
