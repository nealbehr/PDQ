class DropDensityTable < ActiveRecord::Migration
  def up
    drop_table :densities
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
