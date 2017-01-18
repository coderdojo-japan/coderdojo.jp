class ContractsController < ApplicationController
  def index
  end

  def show
    filename = params[:id]
    contract = Contract.new(filename)
    raise unless contract.exists?
    @content = Kramdown::Document.new(contract.content, input: 'GFM').to_html
  end
end
