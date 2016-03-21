class DropApprovedTable < ActiveRecord::Migration
  def up
    drop_table :approveds
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end