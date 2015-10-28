class RemoveFieldFromNeighbors < ActiveRecord::Migration
  def change
    remove_column :neighbors, :neighbor, :integer
  end
end
