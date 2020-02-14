class ChangeTableColumn < ActiveRecord::Migration[6.0]
  def change
    change_column :movies, :description, :text
  end
end
