class CreateOutputs < ActiveRecord::Migration

	def change
		create_table :outputs do |t|
			t.text :street
			t.text :citystatezip
			t.float :time
			t.text :zpid
			t.text :runid
		end
		add_column :outputs , :names , :string , array: true , default: []
		add_column :outputs , :numbers , :string , array: true , default: []
		add_column :outputs , :passes , :string , array: true , default: []
		add_column :outputs , :urls , :string , array: true , default: []
		add_column :outputs , :reason , :string , array: true , default: []
		add_column :outputs , :comments , :string , array: true , default: []
		add_column :outputs , :usage , :string , array: true , default: []

	end
end
