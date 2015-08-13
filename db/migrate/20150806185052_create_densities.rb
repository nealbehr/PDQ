class CreateDensities < ActiveRecord::Migration
  def change
    create_table :densities do |t|
      t.integer :zipcode
      t.float :densityofzip
    end
  end
end
