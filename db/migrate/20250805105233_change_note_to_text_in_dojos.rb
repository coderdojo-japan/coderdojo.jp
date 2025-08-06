class ChangeNoteToTextInDojos < ActiveRecord::Migration[8.0]
  def up
    change_column :dojos, :note, :text, null: false, default: ""
  end
  
  def down
    # 255文字を超えるデータがある場合は警告
    long_notes = Dojo.where("LENGTH(note) > 255").pluck(:id, :name)
    if long_notes.any?
      raise ActiveRecord::IrreversibleMigration, 
        "Cannot revert: These dojos have notes longer than 255 chars: #{long_notes}"
    end
    
    change_column :dojos, :note, :string, null: false, default: ""
  end
end
