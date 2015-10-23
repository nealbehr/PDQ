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

{ street: "725 North 63rd Street", citystatezip: "Seattle, WA 98103"},
{ street: "5510 18th Street NW", citystatezip: "Gig Harbor, WA 98335"},
{ street: "1853 Pheasant Run Terrace", citystatezip: "Brentwood, CA 94513"},
{ street: "1625 Campesino Ct", citystatezip: "Alamo, CA 94507"},
{ street: "5 Owl Hill Ct", citystatezip: "Orinda, CA 94563"},
{ street: "884 48TH AVENUE", citystatezip: "SAN FRANCISCO, CA 94121"},
{ street: "5118 Crown St", citystatezip: "San Diego, CA 92110"},
{ street: "1576 Hillgrade Avenue", citystatezip: "Alamo, CA 94507"},
{ street: "114 Lucille Way", citystatezip: "Orinda, CA 94563"},
{ street: "5616 Buffalo Ave", citystatezip: "Van Nuys, CA 91401"},
{ street: "1736 Westminster Dr", citystatezip: "Cardiff, CA 92007"},
{ street: "609 E. STREET", citystatezip: "PETALUMA, CA 94952"},
{ street: "2574 Hollyview Ct", citystatezip: "Martinez, CA 94553"},
{ street: "4316 North 37th Street", citystatezip: "Tacoma, WA 98407"},
{ street: "5624 Evolene St", citystatezip: "Danville, CA 94506"},
{ street: "7887 Shepherd Canyon Rd", citystatezip: "Oakland, CA 94611"},
{ street: "2612 Buena Vista Ave", citystatezip: "Alameda, CA 94501"},
{ street: "952 Driscoll Rd", citystatezip: "Fremont, CA 94539"},
{ street: "2160 Vintage Ln", citystatezip: "Livermore, CA 94550"},
{ street: "3370 Gardella Plaza", citystatezip: "Livermore, CA 94551"},
{ street: "1682 Anamor St", citystatezip: "Redwood City, CA 94061"},
{ street: "690 East I St", citystatezip: "Benicia, CA 94510"},
{ street: "41 Hagen Oaks Ct", citystatezip: "Alamo, CA 94507"},


{ street: "3377 Biz Point Rd", citystatezip: "Anacortes, WA 98221"},
{ street: "22 OLD LANDING ROAD", citystatezip: "TIBRON, CA 94920"},
{ street: "31 Calstan Pl", citystatezip: "Clifton, NJ 713"},
{ street: "1840 Calle Suenos", citystatezip: "Glendale, CA 91208"},
{ street: "22383 Cass Ave", citystatezip: "Woodland Hills, CA 91364"},
{ street: "4015 ORTEGA STREET", citystatezip: "SAN FRANCISCO, CA 94122"},
{ street: "31 Calstan Pl", citystatezip: "Clifton, NJ 7013"},
{ street: "10814 Sugar Maple Ter", citystatezip: "Upper Marlboro, MD 20774"},
{ street: "1250 Morey Cir", citystatezip: "Hollister, CA 95023"},
{ street: "527 Chinquapin Ave", citystatezip: "Carlsbad, CA 92008"},
{ street: "1869 Coolcrest Ave", citystatezip: "Upland, CA 91784"},
{ street: "18335 Gum Tree Lane", citystatezip: "Huntington Beach, CA 92646"},
{ street: "11011 Cherry Hill Dr", citystatezip: "North Tustin, CA 92705"},
{ street: "753 Cypress Ave", citystatezip: "San Bruno, CA 94066"},
{ street: "461 Sea Ridge Drive", citystatezip: "La Jolla, CA 92037"},
{ street: "79 VIA DE LAURENCIO", citystatezip: "CHULA VISTA, CA 91910"},
{ street: "42043 Roanoake St", citystatezip: "Temecula, CA 92591"},
{ street: "3740 Gold Creek Court", citystatezip: "West Sacramento, CA 95691"},
{ street: "5 Peninsula Ct.", citystatezip: "Napa, CA 94559"},
{ street: "1101 Mandarin", citystatezip: "Upper Marlboro, MD 20774"},
{ street: "4541 EAST BROADWAY", citystatezip: "LONG BEACH, CA 90803"},
{ street: "11351 NE WING POINT WAY", citystatezip: "BAINBRIDGE ISLAND, WA 98110"},
{ street: "355 Orange Street", citystatezip: "Oakland, CA 94610"},
{ street: "6141 Anthony Ave.", citystatezip: "Garden Grove, CA 92845"},
{ street: "11264 Marwick Dr", citystatezip: "Dublin, CA 94568"},
{ street: "4661 Arabian Way", citystatezip: "Antioch, CA 94531"},
{ street: "12624 266th Ave SE", citystatezip: "Monroe, WA 98272"},
{ street: "3212 Terrace Beach Drive", citystatezip: "Vallejo, CA 94591"},
{ street: "2730 OUTPOST DRIVE", citystatezip: "LOS ANGELES, CA 90068"},
{ street: "2768 35TH AVENUE", citystatezip: "SAN FRANCISCO, CA 94116"},
{ street: "9957 Basswood Ct", citystatezip: "Ventura, CA 93004"},
{ street: "6782 Cumberland Dr.", citystatezip: "Huntington Beach, CA 92647"},
{ street: "1763 Whitehall Rd", citystatezip: "Encinitas, CA 92024"},
{ street: "2991 Alexis Dr", citystatezip: "Palo Alto, CA 94304"},
{ street: "16700 Donmetz St", citystatezip: "Granada Hills, CA 91344"},
{ street: "310 Chilense Court", citystatezip: "San Ramon, CA 94582"},
{ street: "1622 SPARKLING WAY", citystatezip: "SAN JOSE, CA 95125"},
{ street: "19812 Carmania Lane", citystatezip: "Huntington Beach, CA 92646"},
{ street: "3 Council Crest Drive", citystatezip: "Corte Madera, CA 94925"},
{ street: "25232 DEL RIO", citystatezip: "LAGUNA NIGUEL, CA 92677"},
{ street: "310 Chilense Court", citystatezip: "San Ramon, CA 94582"},
{ street: "940 Forest Avenue", citystatezip: "Pacific Grove, CA 93950"},
{ street: "32927 Calle de La Burrita", citystatezip: "Malibu, CA 90265"},
{ street: "1119 Hillcrest Blvd", citystatezip: "Millbrae, CA 94030"},
{ street: "319 Felipe Common", citystatezip: "Fremont, CA 94539"},
{ street: "305 Sequoia Terrace", citystatezip: "Danville, CA 94506"},
{ street: "18256 Carlton Avenue", citystatezip: "Castro Valley, CA 94546"},
{ street: "127 Saint Francis Court", citystatezip: "Danville, CA 94526"},
{ street: "14 Northridge Lane", citystatezip: "Lafayette, CA 94549"},
{ street: "1703 Chapparal Lane", citystatezip: "Lafayette, CA 94549"},
{ street: "1251 Sheppard Court", citystatezip: "Walnut Creek, CA 94598"},
{ street: "942 Meander Drive", citystatezip: "Walnut Creek, CA 94598"},
{ street: "1549 Springbrook Road", citystatezip: "Walnut Creek, CA 94597"},
{ street: "113 11th STREET", citystatezip: "PACIFIC GROVE, CA 93950"},
{ street: "139 COLBY STREET", citystatezip: "SAN FRANCISCO, CA 94134"},
{ street: "19 DEL MONTE STREET", citystatezip: "SAN FRANCISCO, CA 94112"},
{ street: "5223 BLACKHAWK DRIVE", citystatezip: "DANVILLE, CA 94506"},
{ street: "1558 45TH AVENUE", citystatezip: "SAN FRANCISCO, CA 94122"},
{ street: "240 DUNCAN STREET", citystatezip: "SAN FRANCISCO, CA 94131"},
{ street: "2236 GARNET DRIVE", citystatezip: "VALLEJO, CA 94591"},


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