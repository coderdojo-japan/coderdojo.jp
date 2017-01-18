class ContractsController < ApplicationController
  def index
  end

  def show
    filename = params[:id]
    contract = Contract.new(filename)
    raise unless contract.exists?
    @content = contract.content
  end
end
