class CreateCensustracts < ActiveRecord::Migration
	def change
		change_table :censustracts do |t|
			t.float :home
			t.float :name
			t.float :area
			t.float :pop
			t.float :hu
		end
	end
end