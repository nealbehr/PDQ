class AddPlaceIdToOutputs < ActiveRecord::Migration
  def change
    add_column :outputs, :place_id, :string
  end
end
