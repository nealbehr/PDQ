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
{ street: "26717 SE 37TH ST", citystatezip: "ISSAQUAH, WA 98029"},


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
