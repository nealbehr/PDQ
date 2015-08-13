class CreateApproveds < ActiveRecord::Migration
  def change
    create_table :approveds do |t|
      t.integer :zipcode
      t.boolean :status
    end
  end
end
