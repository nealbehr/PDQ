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

	{ street: "656 AHWAHNEE COURT", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "1461 QUAIL VIEW CIR", citystatezip: "WALNUT CREEK, CA 94597"},
	{ street: "622 NANTUCKET CT", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "26 AUTUMN TRAIL LN", citystatezip: "WALNUT CREEK, CA 94595-1405"},
	{ street: "19 HANSON LN", citystatezip: "WALNUT CREEK, CA 94596"},
	{ street: "3037 NARANJA DR", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "1530 SORREL CT", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "235 Nob Hill Drive", citystatezip: "WALNUT CREEK, CA 94596-6708"},
	{ street: "620 Sugarloaf Court", citystatezip: "WALNUT CREEK, CA 94596"},
	{ street: "11 BARRY CT", citystatezip: "WALNUT CREEK, CA 94597"},
	{ street: "230 EL CAMINO CORTO", citystatezip: "WALNUT CREEK, CA 94596"},
	{ street: "716 Tampico", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "601 WINTERGREEN LN", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "107 YGNACIO CT", citystatezip: "WALNUT CREEK, CA 94598"},
	{ street: "1900 2nd Avenue", citystatezip: "WALNUT CREEK, CA 94597"},
	{ street: "1141 VALLECITO COURT", citystatezip: "LAFAYETTE, CA 94549-2831"},
	{ street: "1182 CAMINO VALLECITO", citystatezip: "LAFAYETTE, CA 94549"},
	{ street: "3986 N PEARDALE DR", citystatezip: "LAFAYETTE, CA 94549"},
	{ street: "3284 Surmont Drive", citystatezip: "LAFAYETTE, CA 94549"},
	{ street: "2447 CHERRY HILLS DR", citystatezip: "LAFAYETTE, CA 94549"},
	{ street: "125 WESTCHESTER ST", citystatezip: "MORAGA, CA 94556-1756"},
	{ street: "30 QUAIL XING", citystatezip: "MORAGA, CA 94556-2635"},
	{ street: "5 PASEO LINARES", citystatezip: "MORAGA, CA 94556"},
	{ street: "50 DON GABRIEL WAY", citystatezip: "ORINDA, CA 94563"},
	{ street: "29 CRESCENT DR", citystatezip: "ORINDA, CA 94563"},


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