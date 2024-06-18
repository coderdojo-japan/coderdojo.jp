class AddNoteToDojos < ActiveRecord::Migration[6.1]
  def change
    add_column :dojos, :note, :string, null: false, default: ""
  end
end
