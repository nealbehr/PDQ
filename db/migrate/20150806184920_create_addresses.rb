class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.text :street
      t.text :citystatezip
    end
  end
end
