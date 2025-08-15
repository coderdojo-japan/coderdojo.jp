class RemoveIsActiveFromDojos < ActiveRecord::Migration[8.0]
  def change
    # is_active カラムを削除
    # このカラムは inactivated_at カラムと重複していたため削除
    # Issue #1734: https://github.com/coderdojo-japan/coderdojo.jp/issues/1734
    remove_column :dojos, :is_active, :boolean
  end
end
