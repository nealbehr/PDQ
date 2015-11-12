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

{ street: "5401 Penny Ln", citystatezip: "Pleasanton, CA 94588"},
{ street: "430 Meadow View Ln", citystatezip: "Clayton, CA 94517"},
{ street: "12544 SORA WAY", citystatezip: "SAN DEIGO, CA 92129"},
{ street: "1746 Pierce Lane", citystatezip: "Placentia, CA 92870"},
{ street: "3707 39th Ave S", citystatezip: "Seattle, WA 98144"},
{ street: "3859 Karen Lynn Dr", citystatezip: "Glendale, CA 91206"},
{ street: "50 California St", citystatezip: "San Francisco, CA 94111"},
{ street: "918 Boar Cir", citystatezip: "Fremont, CA 94539"},
{ street: "50 California Street", citystatezip: "San Francisco, CA 94111"},
{ street: "42975 Paseo Padre Pkwy", citystatezip: "Fremont, CA 94539"},
{ street: "2612 Buena Vista Ave", citystatezip: "Alameda, CA 94501"},
{ street: "1853 Pheasant Run Terrace", citystatezip: "Brentwood, CA 94513"},
{ street: "608 Bourne Ct", citystatezip: "Danville, CA 94506"},
{ street: "5706 Starfish Ct", citystatezip: "Discovery Bay, CA 94505"},
{ street: "3215 Nathan Ct", citystatezip: "Fremont, CA 94539"},
{ street: "43207 Palm Pl", citystatezip: "Fremont, CA 94539"},
{ street: "952 Driscoll Rd", citystatezip: "Fremont, CA 94539"},
{ street: "47647 Hoyt St", citystatezip: "Fremont, CA 94539"},
{ street: "1069 Camero Way", citystatezip: "Fremont, CA 94539"},
{ street: "1534 Pyrite Pl", citystatezip: "Livermore, CA 94550"},
{ street: "2160 Vintage Ln", citystatezip: "Livermore, CA 94550"},
{ street: "3370 Gardella Plaza", citystatezip: "Livermore, CA 94551"},
{ street: "8863 Skyline Blvd", citystatezip: "Oakland, CA 94611"},
{ street: "14 Francisco Ct", citystatezip: "Orinda, CA 94563"},
{ street: "60 La Espiral", citystatezip: "Orinda, CA 94563"},
{ street: "12 Overhill Rd", citystatezip: "Orinda, CA 94563"},
{ street: "112 Fiesta Cir", citystatezip: "Orinda, CA 94563"},
{ street: "5047 Muirwood Dr", citystatezip: "Pleasanton, CA 94588"},
{ street: "4972 Mohr Ave", citystatezip: "Pleasanton, CA 94566"},
{ street: "509 Levant Ct", citystatezip: "San Ramon, CA 94582"},
{ street: "206 Cullens Ct", citystatezip: "San Ramon, CA 94582"},
{ street: "498 Florence Dr", citystatezip: "Lafayette, CA 94549"},
{ street: "319 Upton Pyne Dr", citystatezip: "Brentwood, CA 94513"},
{ street: "5422 Oneida Way", citystatezip: "Antioch, CA 94531"},
{ street: "319 Upton Pyne Dr", citystatezip: "Brentwood, CA 94513"},
{ street: "6765 Rancho Ct", citystatezip: "Pleasanton, CA 94588"},
{ street: "39 Walker Lane", citystatezip: "Bloomfield, CT 6002"},
{ street: "1377 Richardson Ave", citystatezip: "Los Altos, CA 94024"},
{ street: "34041 MAZO DRIVE", citystatezip: "DANA POINT, CA 92629"},
{ street: "26 Autumn Trail Ln", citystatezip: "Walnut Creek, CA 94595"},
{ street: "243 S 21st St", citystatezip: "Richmond, CA 94804"},
{ street: "1625 Campesino Ct", citystatezip: "Alamo, CA 94507"},
{ street: "5 Owl Hill Ct", citystatezip: "Orinda, CA 94563"},
{ street: "41 Hagen Oaks Ct", citystatezip: "Alamo, CA 94507"},
{ street: "4636 Fallow Way", citystatezip: "Antioch, CA 94509"},
{ street: "826 Santa Ana Dr", citystatezip: "Pittsburg, CA 94565"},
{ street: "1682 Anamor St", citystatezip: "Redwood City, CA 94061"},
{ street: "574 W. Gravino Dr.", citystatezip: "Mountain House, CA 95391"},
{ street: "690 East I St", citystatezip: "Benicia, CA 94510"},




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