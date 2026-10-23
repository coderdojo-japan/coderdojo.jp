# 申請フォームで使わなくなった列を整理する（中身は 20261023150000 で空にした）
class RemoveUnusedColumnsFromStretch3s < ActiveRecord::Migration[8.1]
  def change
    remove_column :stretch3s, :email,            :string
    remove_column :stretch3s, :parent_name,      :string
    remove_column :stretch3s, :participant_name, :string
    remove_column :stretch3s, :dojo_name,        :string
  end
end
