class DocsController < ApplicationController
  def index
    @title = 'CoderDojo Japan ドキュメント集'
    @docs  = Document.all
    @url   = request.url
  end

  def show
    filename = params[:id]
    @doc = Document.new(filename)
    redirect_to scrivito_path(Obj.root) if not @doc.exists?
    @content = Kramdown::Document.new(@doc.content, input: 'GFM').to_html
  end
end
