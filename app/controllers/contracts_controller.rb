class ContractsController < ApplicationController
  def index
    @contracts = Contract.all
  end

  def show
    filename = params[:id]
    contract = Contract.new(filename)
    if contract.exists?
      @content = Kramdown::Document.new(contract.content, input: 'GFM').to_html
    else
      redirect_to scrivito_path(Obj.root)
    end
  end
end
