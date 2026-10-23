# 申請フォームで使わなくなった列の中身を空にする。列そのものは、後で別に消す
class ClearUnusedColumnsInStretch3s < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE stretch3s SET email = NULL, parent_name = NULL, participant_name = NULL, dojo_name = NULL
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
