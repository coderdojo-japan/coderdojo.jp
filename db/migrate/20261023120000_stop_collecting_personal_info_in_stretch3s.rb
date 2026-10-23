# Stretch3 の申込で個人情報（メールアドレス・保護者と利用者の名前）を集めるのをやめ、
# 活動中の道場から選んでもらう。既存の行の列は、消すかを別に決めるまで残す（NULL を許すだけ）。
class StopCollectingPersonalInfoInStretch3s < ActiveRecord::Migration[8.1]
  def change
    add_reference :stretch3s, :dojo, foreign_key: true, null: true
    change_column_null :stretch3s, :email, true
    change_column_null :stretch3s, :parent_name, true
    change_column_null :stretch3s, :participant_name, true
    change_column_null :stretch3s, :dojo_name, true
  end
end
