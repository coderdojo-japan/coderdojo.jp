require 'csv'

csv_data = CSV.generate do |csv|
  # ヘッダー行
  csv << ['ID', '道場名', '道場数', '都道府県', 'URL', '設立日', '状態']
  
  # データ行
  @dojos.each do |dojo|
    csv << [
      dojo[:id],
      dojo[:name],
      dojo[:counter],
      dojo[:prefecture],
      dojo[:url],
      dojo[:created_at].strftime("%F"),
      dojo[:is_active] ? 'アクティブ' : '非アクティブ'
    ]
  end
  
  # 合計行を追加
  csv << []
  csv << ['合計', "#{@dojos.length}道場", @counter_sum, '', '', '', '']
end