# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)




Address.destroy_all

Address.create!([
      {street: "40 KREUSE CANYON ROAD", citystatezip: "NAPA, CA 94559"},
      {street: "75 ORA WAY UNIT 302D", citystatezip: "SAN FRANCISCO, CA 94131"},
      {street: "9 ADRIAN TERRACE", citystatezip: "SAN RAFAEL, CA 94903"},
      {street: "93 CAROLINA DRIVE", citystatezip: "BENICIA, CA 94510"},
      {street: "296 DEVONSHIRE COURT", citystatezip: "VALLEJO, CA 94591"},
      {street: "6032 PLUMAS AVENUE", citystatezip: "RICHMOND, CA 94804"},
      {street: "693 ABBEY COURT", citystatezip: "BENICIA, CA 94510"},
      {street: "505 LEXINGTON DRIVE", citystatezip: "VALLEJO, CA 94591"},
      {street: "355 1ST STREET UNIT 2306", citystatezip: "SAN FRANCISCO, CA 94105"},
      {street: "1980 ADAMS STREET", citystatezip: "YOUNTVILLE, CA 94599"}
	])

puts "Addresses Done"

# User.create!([
# 	{ email: "brad.lookabaugh@1rex.com", password: "123456789", password_confirmation: "123456789", admin: true },
# 	])
puts "Users Done"