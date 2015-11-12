class AddDetailsToOutputs < ActiveRecord::Migration
  def change
    add_column :outputs, :product, :string
    add_column :outputs, :date, :text
  end
end
