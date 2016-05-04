# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)




Address.destroy_all

Address.create!([
      {street: "139 BYXBEE", citystatezip: "SAN FRANCISCO, CA 94132"},
      {street: "132 BALTIMORE WAY", citystatezip: "SAN FRANCISCO, CA 94112"},
      {street: "326 HOLLADAY AVENUE", citystatezip: "SAN FRANCISCO, CA 94110"},
      {street: "18 LANSING STREET UNIT 403", citystatezip: "SAN FRANCISCO, CA 94105"},
      {street: "40 VILLA AVENUE", citystatezip: "SAN RAFAEL, CA 94901"},
      {street: "400 SPEAR STREET UNIT 203", citystatezip: "SAN FRANCISCO, CA 94105"},
      {street: "246 2ND STREET UNIT 1704", citystatezip: "SAN FRANCISCO, CA 94105"},

	])

puts "Addresses Done"

# User.create!([
# 	{ email: "brad.lookabaugh@1rex.com", password: "123456789", password_confirmation: "123456789", admin: true },
# 	])
puts "Users Done"

