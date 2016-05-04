class AddDataSourceToOutputs < ActiveRecord::Migration
  def change
    add_column :outputs, :data_source, :string, array: true, default: []
  end
end
