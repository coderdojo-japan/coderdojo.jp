# 取り込み（dojos:update_db_by_yaml）が常に空文字を入れるだけで、どこからも読まれていない列を削除する。
# YAML に無い古い行には以前の値が残りうるので、列ごと消す
class RemoveEmailFromDojos < ActiveRecord::Migration[8.1]
  def change
    remove_column :dojos, :email, :string
  end
end
