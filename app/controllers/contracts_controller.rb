class ContractsController < ApplicationController
  def index
    @contracts = Contract.all
  end

  def show
    filename = params[:id]
    contract = Contract.new(filename)
    raise unless contract.exists?
    @content = Kramdown::Document.new(contract.content, input: 'GFM').to_html
  end
end
