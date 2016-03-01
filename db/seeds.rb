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
{ street: "941 Truro Ln", citystatezip: "Crofton, MD 21114"},
{ street: "13180 Derby Ave", citystatezip: "Chino, CA 91710"},
{ street: "76 Windchime", citystatezip: "Irvine, CA 92603"},
{ street: "14964 Preston Drive", citystatezip: "Fontana, CA 92336"},
{ street: "4661 Arabian Way", citystatezip: "Antioch, CA 94531"},
{ street: "12803 WITHERSPOON RD", citystatezip: "CHINO, CA 91710"},
{ street: "1208 Rucker Ave", citystatezip: "Everett, WA 98201"},
{ street: "15348 Villaba Rd", citystatezip: "Fontana, CA 92337"},

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

User.create!([
	{ email: "neal.behrend@1rex.com", password: "123456789", password_confirmation: "123456789", admin: true },
	{ email: "avita.datt@1rex.com", password: "123456789", password_confirmation: "123456789", admin: false },

	])
