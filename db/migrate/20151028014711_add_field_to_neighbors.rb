class AddFieldToNeighbors < ActiveRecord::Migration
  def change
    add_column :neighbors, :neighbor, :text
  end
end
