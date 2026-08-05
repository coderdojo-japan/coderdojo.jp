class AddGlobalClubIdToDojos < ActiveRecord::Migration[8.0]
  # Raspberry Pi 財団の Clubs データベース上のクラブ ID (UUID)。
  # 値は db/dojos.yml が持ち、dojos:update_db_by_yaml でこの列に入る。
  #
  # null 許容にしている。掲載を終えた道場は Clubs 側から消えており、
  # 全件が値を持つ状態にはならないため（2026-08 時点で 261/339）。
  # 最終的に null: false を目指す方針は Issue #1616 に記録している。
  # https://github.com/coderdojo-japan/coderdojo.jp/issues/1616
  #
  # PostgreSQL のユニークインデックスは NULL を重複とみなさないので、
  # 値を持たない道場が共存できる。ただし空文字は 1 件しか許されないため、
  # update_db_by_yaml 側で nil に正規化する。
  def change
    add_column :dojos, :global_club_id, :string
    add_index  :dojos, :global_club_id, unique: true
  end
end
