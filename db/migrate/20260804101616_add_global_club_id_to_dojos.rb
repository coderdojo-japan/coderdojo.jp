class AddGlobalClubIdToDojos < ActiveRecord::Migration[8.0]
  def change
    # Raspberry Pi 財団の Clubs API 上のクラブ ID (UUID)。
    # DojoMap はこの ID で Clubs API と Japan DB を突合する。
    #
    # null 許容にしている理由: 閉鎖などで Clubs API 側に存在しない Dojo が
    # 現時点で 76 件あり、すべてを埋めることはできないため。
    # PostgreSQL のユニークインデックスは NULL を複数許すので共存できる。
    #
    # 設計文書 (PR #1747) が指定する null: false を見送った経緯や、
    # 初期データの投入方法は PR #1867 を参照。
    # https://github.com/coderdojo-japan/coderdojo.jp/pull/1867
    add_column :dojos, :global_club_id, :string
    add_index  :dojos, :global_club_id, unique: true
  end
end
