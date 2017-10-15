class DocsController < ApplicationController
  def index
    @docs = Document.all
  end

  def show
    filename = params[:id]
    @doc = Document.new(filename)
    redirect_to scrivito_path(Obj.root) if not @doc.exists?
    @content = Kramdown::Document.new(@doc.content, input: 'GFM').to_html
  end
end
