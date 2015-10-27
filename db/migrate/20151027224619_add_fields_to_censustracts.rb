class AddFieldsToCensustracts < ActiveRecord::Migration
  def change
    add_column :censustracts, :state, :float
    add_column :censustracts, :lat, :float
    add_column :censustracts, :lon, :float
    add_column :censustracts, :stringname, :text
  end
end
