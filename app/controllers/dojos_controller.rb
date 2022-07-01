class DojosController < ApplicationController
  def index
    @dojo_data = []
    Dojo.all.each do |dojo|
      @dojo_data << {
        url:         dojo.url,
        name:        dojo.name,
        order:       dojo.order,
        prefecture:  dojo.prefecture.region,
        linked_text: "<a href='#{dojo.url}'>#{dojo.name}</a>（#{dojo.prefecture.region}）",
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
