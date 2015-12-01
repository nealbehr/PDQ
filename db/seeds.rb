# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)




Density.destroy_all

puts "Densities Done"

Address.destroy_all

Address.create!([

{ street: "1308 Corte De Los Vecinos", citystatezip: "WALNUT CREEK, CA 94598"},
{ street: "100 ARLENE DR", citystatezip: "WALNUT CREEK, CA 94595"},
{ street: "1175 CALDER LN", citystatezip: "WALNUT CREEK, CA 94598"},
{ street: "416 Nob Hill Drive", citystatezip: "WALNUT CREEK, CA 94596"},
{ street: "1931 ARGONNE DR", citystatezip: "WALNUT CREEK, CA 94598"},
{ street: "3 Paseo Linares", citystatezip: "MORAGA, CA 94556"},
{ street: "44 Sullivan Drive", citystatezip: "MORAGA, CA 94556"},
{ street: "21 SANDY CT", citystatezip: "ORINDA, CA 94563"},





	])

puts "Addresses Done"

if Approved.count < 1000000

	puts "Burn it to the ground!"
	Approved.destroy_all

	Approved.create!([

		{ zipcode: 6902, status: false },
		{ zipcode: 6901, status: false },


		])

end
puts "Approved Zip Codes Done"