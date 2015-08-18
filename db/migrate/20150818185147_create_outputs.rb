class CreateOutputs < ActiveRecord::Migration

	def change
		create_table :outputs do |t|
			t.text :street
			t.text :citystatezip
			t.float :time
			t.text :names
		end
		add_column :outputs , :testholders , :string , array: true , default: []
	end
end
