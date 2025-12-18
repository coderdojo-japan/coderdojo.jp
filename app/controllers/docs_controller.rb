class DocsController < ApplicationController
  def index
    @title = '📚 CoderDojo 資料集'
    @desc  = 'CoderDojo に関する資料を<br class="ignore-pc">トピック毎にまとめたページです。'
    @url   = request.url
    @docs  = Document.all.delete_if.each do |doc|
      # 記録用ページと英文ページはドキュメント一覧から非表示にする
      doc.filename.start_with? '_' or doc.filename.end_with? '_en'
    end
  end

  def kata
    @dojo_count = Dojo.active_dojos_count
  end

  def show
    @doc = Document.new(params[:id])
    redirect_to root_url unless @doc.exist?

    if @doc.content.include? "NUM_OF_"
      @doc.content.gsub! "{{ NUM_OF_JAPAN_DOJOS }}",   Dojo.active_dojos_count.to_s
      @doc.content.gsub! "{{ NUM_OF_PARTNERSHIPS }}",  Dojo::NUM_OF_PARTNERSHIPS
      @doc.content.gsub! "{{ NUM_OF_ANNUAL_EVENTS }}", Dojo::NUM_OF_ANNUAL_EVENTS
      @doc.content.gsub! "{{ NUM_OF_ANNUAL_NINJAS }}", Dojo::NUM_OF_ANNUAL_NINJAS
      @doc.content.gsub! "{{ NUM_OF_TOTAL_EVENTS }}",  Dojo::NUM_OF_TOTAL_EVENTS
      @doc.content.gsub! "{{ NUM_OF_TOTAL_NINJAS }}",  Dojo::NUM_OF_TOTAL_NINJAS
    end

    # INACTIVE_THRESHOLD を日本語の期間表記に変換
    if @doc.content.include? "INACTIVE_THRESHOLD"
      # 1.year → "１年間", 6.months → "６ヶ月間" のように変換
      threshold_in_months = Dojo::INACTIVE_THRESHOLD.to_i / 1.month.to_i
      threshold_text = if threshold_in_months >= 12
                         years = threshold_in_months / 12
                         "#{years.to_s.tr('0-9', '０-９')}年間"
                       else
                         "#{threshold_in_months.to_s.tr('0-9', '０-９')}ヶ月間"
                       end
      @doc.content.gsub! "{{ INACTIVE_THRESHOLD }}", threshold_text
    end

    @content    = Kramdown::Document.new(@doc.content, input: 'GFM').to_html
    @url        = request.url
    @meta_image = Nokogiri::HTML.parse(@content).at("//img")&.attribute('data-src')&.value || "/img/ogp-docs.jpeg"
    if @meta_image.end_with? '.webp'
      # .webp -> .jpg
      # .webp -> .png
      @meta_image.gsub!('.webp', '.jpg')  if File.exist? "public/#{@meta_image[0..-6]}.jpg"
      @meta_image.gsub!('.webp', '.jpeg') if File.exist? "public/#{@meta_image[0..-6]}.jpeg"
      @meta_image.gsub!('.webp', '.png')  if File.exist? "public/#{@meta_image[0..-6]}.png"
    end

    # Add here if you want to optimize meta description.
    case @doc.filename
    when 'about-partnership' then
      @doc.description = '法人向けの CoderDojo 説明ページです。提携・連携をご検討する際にご活用ください。これまでの提携事例や統計情報、社内稟議用のスライド資料などがまとまっています。'
    when 'english' then
      @lang = 'en'
    end
  end
end
