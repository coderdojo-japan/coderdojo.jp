require 'csv'

csv_data = CSV.generate do |csv|
  # ヘッダー行
  # 選択年に応じて状態カラムのヘッダーを変更
  status_header = if @selected_year
    if @selected_year == Date.current.year
      "状態 (#{Date.current.strftime('%Y年%-m月%-d日')}時点)"
    else
      "状態 (#{@selected_year}年末時点)"
    end
  else
    '状態'
  end
  
  # 全期間の場合のみ閉鎖日カラムを追加
  if @selected_year
    csv << ['ID', '道場名', '道場数', '都道府県', 'URL', '設立日', status_header]
  else
    csv << ['ID', '道場名', '道場数', '都道府県', 'URL', '設立日', status_header, '閉鎖日']
  end
  
  # データ行
  @dojos.each do |dojo|
    row = [
      dojo[:id],
      dojo[:name],
      dojo[:counter],
      dojo[:prefecture],
      dojo[:url],
      dojo[:created_at].strftime("%F"),
      dojo[:is_active] ? 'アクティブ' : '非アクティブ'
    ]
    
    # 全期間の場合のみ閉鎖日を追加
    if !@selected_year
      row << (dojo[:inactivated_at] ? dojo[:inactivated_at].strftime("%F") : '')
    end
    
    csv << row
  end
  
  # 合計行を追加
  csv << []
  if @selected_year
    csv << ['合計', "#{@dojos.length}道場", @counter_sum, '', '', '', '']
  else
    csv << ['合計', "#{@dojos.length}道場", @counter_sum, '', '', '', '', '']
  end
end