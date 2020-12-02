class DocsController < ApplicationController
  def index
    @title = 'CoderDojo Japan ドキュメント集'
    @desc  = 'CoderDojo に関する公式情報を本ページでまとめています。'
    @docs  = Document.all.reject{|doc| doc.title.start_with? '📆 予定表'}
    @url   = request.url
  end

  def show
    @doc = Document.new(params[:id])
    redirect_to root_url unless @doc.exists?
    if @doc.content.include? "NUM_OF_"
      @doc.content.gsub! "{{ NUM_OF_JAPAN_DOJOS }}", Dojo.active_dojos_count.to_s
      @doc.content.gsub! "{{ NUM_OF_WORLD_DOJOS }}", Dojo::NUM_OF_WORLD_DOJOS
      @doc.content.gsub! "{{ NUM_OF_COUNTRIES }}",   Dojo::NUM_OF_COUNTRIES
    end
    @content = Kramdown::Document.new(@doc.content, input: 'GFM').to_html
    @url     = request.url
  end
end
