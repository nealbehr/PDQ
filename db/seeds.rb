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
{ street: "21937 7TH AVE S #212", citystatezip: "DES MOINES, WA 98198"},
{ street: "26826 OLD OWEN ROAD", citystatezip: "MONROE, WA 98272"},
{ street: "3022 101ST PL SE", citystatezip: "EVERETT, WA 98208"},
{ street: "6903 119TH STREET CT E", citystatezip: "PUYALLUP, WA 98373"},
{ street: "*** TBD LOAN - PROPERTY NOT SELECTED ***", citystatezip: "EVERETT, WA 98208"},
{ street: "11056 NE 14TH ST", citystatezip: "BELLEVUE, WA 98004"},
{ street: "LOT 260 INSPIRATION RIDGE", citystatezip: "BONNEY LAKE, WA 98391"},
{ street: "11349 20th Ave. NE", citystatezip: "Seattle, WA 98125"},
{ street: "3715 CRYSTAL RIDGE DRIVE SE", citystatezip: "PUYALLUP, WA 98372"},
{ street: "30500 MOUNTIAN LOOP HWY", citystatezip: "GRANITE FALLS, WA 98252"},
{ street: "5 A MUNDY RD", citystatezip: "TWISP, WA 98856"},
{ street: "17334 428TH AVENUE SE", citystatezip: "NORTH BEND, WA 98045"},
{ street: "14229 320TH AVE NE", citystatezip: "DUVALL, WA 98019"},
{ street: "17820 NE 101ST CT", citystatezip: "REDMOND, WA 98052"},
{ street: "19230 25TH AVENUE SE", citystatezip: "BOTHELL, WA 98012"},
{ street: "8320 75TH DR NE", citystatezip: "MARYSVILLE, WA 98270"},
{ street: "11619 5TH AVE S", citystatezip: "SEATTLE, WA 98168"},
{ street: "25702 162ND PLACE SE", citystatezip: "COVINGTON, WA 98042"},
{ street: "11325 19TH AVE SE #C111", citystatezip: "EVERETT, WA 98208"},
{ street: "400 6TH AVENUE", citystatezip: "TWISP, WA 98856"},
{ street: "12333 25TH AVENUE SE", citystatezip: "EVERETT, WA 98208"},
{ street: "22825 102ND AVE SE", citystatezip: "WOODINVILLE, WA 98077"},
{ street: "15608 SE 128TH STREET", citystatezip: "RENTON, WA 98059"},
{ street: "24026 MERIDIAN AVE S", citystatezip: "BOTHELL, WA 98021"},
{ street: "8442 SOUTH A ST", citystatezip: "TACOMA, WA 98444"},
{ street: "9316 NE 30TH STREET", citystatezip: "CLYDE HILL, WA 98004"},
{ street: "39532 314TH ST NE", citystatezip: "ARLINGTON, WA 98223"},
{ street: "14621 45TH PLACE W", citystatezip: "LYNNWOOD, WA 98087"},
{ street: "12117 SE 70TH STREET", citystatezip: "RENTON, WA 98056"},
{ street: "24303 116TH AVE W", citystatezip: "WOODWAY, WA 98020"},
{ street: "3205 E L ST", citystatezip: "TACOMA, WA 98404"},
{ street: "5063 66th Place SE", citystatezip: "Snohomish, WA 98290"},
{ street: "14601 AVON ALLEN ROAD", citystatezip: "MOUNT VERNON, WA 98273"},
{ street: "27923 NE 49TH STREET", citystatezip: "REDMOND, WA 98053"},
{ street: "615 MAPLE HEIGHTS RD", citystatezip: "CAMANO ISLAND, WA 98282"},
{ street: "6C SUMMER ROAD", citystatezip: "WINTHROP, WA 98862"},
{ street: "1009 83RD AVE SE", citystatezip: "LAKE STEVENS, WA 98258"},
{ street: "2949 76TH AVE SE # 81 A", citystatezip: "MERCER ISLAND, WA 98040"},
{ street: "1851 218TH PLACE NE", citystatezip: "SAMMAMISH, WA 98074"},
{ street: "1434 NW 195TH ST", citystatezip: "SHORELINE, WA 98177"},
{ street: "124 N KELLER AVE", citystatezip: "EAST WENATCHEE, WA 98802"},
{ street: "2201 3RD AVENUE, #1503", citystatezip: "SEATTLE, WA 98121"},
{ street: "20605 111TH AVE SW", citystatezip: "VASHON, WA 98070"},
{ street: "15416 40TH AVE W APT 28", citystatezip: "LYNNWOOD, WA 98087"},
{ street: "332 W LEATHERWOOD AVE", citystatezip: "SAN TAN VALLEY, AZ 85140"},
{ street: "11922 207TH AVE E", citystatezip: "BONNEY LAKE, WA 98391"},
{ street: "16011 10TH STREET SE", citystatezip: "SNOHOMISH, WA 98290"},
{ street: "1631 117TH ST. S.", citystatezip: "TACOMA, WA 98444"},
{ street: "7026 119TH PLACE SE", citystatezip: "NEWCASTLE, WA 98056"},
{ street: "8720 PHINNEY AVE N APT. 14", citystatezip: "SEATTLE, WA 98103"},
{ street: "10115 6TH DRIVE SE #A", citystatezip: "EVERETT, WA 98208"},
{ street: "17826 NE 95TH COURT", citystatezip: "REDMOND, WA 98052"},
{ street: "18606 64TH AVE W", citystatezip: "LYNNWOOD, WA 98037"},
{ street: "6308 69TH DR NE", citystatezip: "MARYSVILLE, WA 98270"},
{ street: "*** TBD LOAN - PROPERTY NOT SELECTED ***", citystatezip: "RENTON, WA 98059"},
{ street: "6119 190TH ST SW", citystatezip: "LYNNWOOD, WA 98036"},
{ street: "3048 224TH AVENUE NE", citystatezip: "SAMMAMISH, WA 98074"},
{ street: "6742 137TH AVE NE APT426", citystatezip: "REDMOND, WA 98052"},
{ street: "31500 3RD PL SW #P102", citystatezip: "FEDERAL WAY, WA 98023"},
{ street: "31500 3rd PL SW #p102", citystatezip: "Federal way, WA 98023"},
{ street: "209 WHITCOMB AVENUE NORTH", citystatezip: "TONASKET, WA 98855"},
{ street: "1311 N TOUCHET ROAD", citystatezip: "DAYTON, WA 99328"},
{ street: "7522 41ST AVE NE", citystatezip: "SEATTLE, WA 98115"},
{ street: "12211 NE 203RD ST", citystatezip: "BOTHELL, WA 98011"},
{ street: "14910 276TH PL NE", citystatezip: "DUVALL, WA 98019"},
{ street: "7820 73RD PL NE", citystatezip: "MARYSVILLE, WA 98270"},
{ street: "16021 NE 105th Court", citystatezip: "Redmond, WA 98052"},
{ street: "17001 INGLEWOOD ROAD NE", citystatezip: "KENMORE, WA 98028"},
{ street: "13305 22ND AVE W.", citystatezip: "LYNNWOOD, WA 98087"},
{ street: "1111", citystatezip: "SEATTLE, WA 98111"},
{ street: "123 DONT KNOW", citystatezip: "CARNATION, WA 98014"},
{ street: "12219 56TH DRIVE NE", citystatezip: "MARYSVILLE, WA 98271"},
{ street: "12916 240TH STREET NE", citystatezip: "ARLINGTON, WA 98223"},
{ street: "5001 CALIFORNIA AVE SW, #102", citystatezip: "SEATTLE, WA 98106"},
{ street: "3324 181ST PLACE NE", citystatezip: "REDMOND, WA 98052"},
{ street: "120 N WYNOOCHEE DRIVE", citystatezip: "HOODSPORT, WA 98548"},
{ street: "*** TBD LOAN - PROPERTY NOT SELECTED ***", citystatezip: "SNOQUALMIE, WA 98065"},
{ street: "1310 N LUCAS PL UNIT 406", citystatezip: "SEATTLE, WA 98103"},
{ street: "427 MAIN AVENUE S, # 37", citystatezip: "NORTH BEND, WA 98045"},
{ street: "19600 NAVARRE COULEE RD", citystatezip: "CHELAN, WA 98816"},
{ street: "12241 43RD AVE S", citystatezip: "SEATTLE, WA 98178"},
{ street: "427 MAIN AVE S APT 37", citystatezip: "NORTH BEND, WA 98045"},
{ street: "137 W MUKILTEO BLVD", citystatezip: "EVERETT, WA 98203"},
{ street: "2116 G STREET", citystatezip: "BELLINGHAM, WA 98225"},
{ street: "2116 G STREET", citystatezip: "BELLINGHAM, WA 98225"},
{ street: "6910 CALIFORNIA AVENUE SW, #45", citystatezip: "SEATTLE, WA 98136"},
{ street: "4949 SAMISH WAY UNIT 53", citystatezip: "BELLINGHAM, WA 98229"},
{ street: "7621 S 124TH ST #7615, #7617, #7619", citystatezip: "SEATTLE, WA 98178"},
{ street: "5725 113TH PL SE", citystatezip: "EVERETT, WA 98208"},
{ street: "111111", citystatezip: "SEATTLE, WA 98111"},
{ street: "2258 250TH PL SE", citystatezip: "SAMMAMISH, WA 98075"},
{ street: "12624 NE 140TH ST", citystatezip: "KIRKLAND, WA 98034"},
{ street: "3107 C ST SE", citystatezip: "AUBURN, WA 98002"},
{ street: "4122 41ST AVE SW", citystatezip: "SEATTLE, WA 98116"},
{ street: "28615 NE 151ST PLACE", citystatezip: "DUVALL, WA 98019"},
{ street: "23206 35TH AVE SE", citystatezip: "BOTHELL, WA 98021"},
{ street: "3239 198TH PL SE", citystatezip: "SAMMAMISH, WA 98075"},
{ street: "21730 130TH ST E", citystatezip: "BONNEY LAKE, WA 98391"},
{ street: "8712 197TH STREET CT E.", citystatezip: "SPANAWAY, WA 98387"},
{ street: "3212 W 21ST AVE", citystatezip: "SPOKANE, WA 99224"},
{ street: "1014 BURTON STREET", citystatezip: "TWISP, WA 98856"},
{ street: "131 157TH AVENUE NE", citystatezip: "BELLEVUE, WA 98008"},
{ street: "31727 190TH AVE SE", citystatezip: "AUBURN, WA 98092"},
{ street: "11111 111", citystatezip: "SAN ANTONIO, TX 78259"},
{ street: "5222 E E ST", citystatezip: "TACOMA, WA 98404"},
{ street: "1208 ORCHARD AVENUE", citystatezip: "SNOHOMISH, WA 98290"},
{ street: "19418 SE 286TH ST", citystatezip: "KENT, WA 98042"},
{ street: "8201 S ALASKA ST", citystatezip: "TACOMA, WA 98408"},
{ street: "9416 1ST AVE NE APT 101", citystatezip: "SEATTLE, WA 98115"},
{ street: "5528 142ND AVENUE SE", citystatezip: "BELLEVUE, WA 98006"},
{ street: "131 157TH AVENUE NE", citystatezip: "BELLEVUE, WA 98007"},
{ street: "1606 N PROCTOR ST", citystatezip: "TACOMA, WA 98406"},
{ street: "6035 S CEDAR STREET", citystatezip: "TACOMA, WA 98409"},
{ street: "1433 113TH AVE SE", citystatezip: "LAKE STEVENS, WA 98258"},
{ street: "1900 MILLFERN DR SE", citystatezip: "MILL CREEK, WA 98012"},
{ street: "1228 E 71ST STREET", citystatezip: "TACOMA, WA 98404"},
{ street: "7637 W GREEN LAKE N", citystatezip: "SEATTLE, WA 98103"},
{ street: "1471 OCEAN DR", citystatezip: "CAMANO ISLAND, WA 98282"},
{ street: "7734 14TH AVE NW", citystatezip: "SEATTLE, WA 98117"},
{ street: "445 SW 121ST ST", citystatezip: "SEATTLE, WA 98146"},
{ street: "818 SHOSHONE DRIVE", citystatezip: "LA CONNER, WA 98257"}



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