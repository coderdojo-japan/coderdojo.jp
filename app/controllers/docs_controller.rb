class DocsController < ApplicationController
  def index
    @docs = Document.all
  end

  def show
    filename = params[:id]
    doc = Document.new(filename)
    if doc.exists?
      @content = Kramdown::Document.new(doc.content, input: 'GFM').to_html
    else
      redirect_to scrivito_path(Obj.root)
    end
  end
end
