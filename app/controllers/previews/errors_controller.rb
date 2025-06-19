class Previews::ErrorsController < ApplicationController
  layout "application"

  def show
    status_code = params[:status_code].to_i

    if status_code == 422
      # 422の時だけは、ファイル名を直接指定
      # Rails標準のRack::Utilsは422を "Unprocessable Content" と解釈しますが、
      # Rambulanceが期待するビュー名は `unprocessable_entity.html.erb` です。
      # この食い違いを吸収するため、422の時だけファイル名を直接指定しています。
      error_page_name = "unprocessable_entity"
    else
      error_page_name = Rack::Utils::HTTP_STATUS_CODES[status_code].downcase.gsub(" ", "_")
    end

    render template: "errors/#{error_page_name}", status: status_code
  end

end
