class CreateNeighbors < ActiveRecord::Migration
	def change
		create_table :neighbors do |t|
			t.float :home
			t.integer :neighbor    
		end
	end
end