class AddDetailsToCensustracts < ActiveRecord::Migration
  def change
    add_column :censustracts, :geoid, :string
    add_column :censustracts, :county, :float
    add_column :censustracts, :tractid, :string
  end
end
