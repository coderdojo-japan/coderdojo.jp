class PokemonsController < ApplicationController
  # ダウンロード機能（POST /pokemon と GET /pokemon/download）は、オンライン版への
  # 移行（2024年度）に伴い停止済み。申込フォームは無効化され、POST のルーティングも
  # コメントアウトされている。未使用となったコードを削除した。
  #
  # 案内ページ（/pokemon）とワークショップ紹介（/pokemon/workshop）は従来どおり。

  # GET /pokemon
  def new; end

  # GET /pokemon/workshop
  def workshop; end
end
