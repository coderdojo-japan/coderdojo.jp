class DocsController < ApplicationController
  def index
    @title = 'CoderDojo Japan ドキュメント集'
    @desc  = '本ページでは、一般向けに公開した文書をまとめています。'
    @docs  = Document.all
    @url   = request.url
  end

  def show
    @doc = Document.new(params[:id])
    redirect_to root_url unless @doc.exists?
    @content = Kramdown::Document.new(@doc.content, input: 'GFM').to_html
    @url     = request.url
  end
end
