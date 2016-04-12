# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)




Address.destroy_all

Address.create!([
{ street: "22 Bay Canyon Road", citystatezip: "Novato, CA 94945"},
{ street: "1151 Moccasin Court", citystatezip: "Clayton, CA 94517"},
{ street: "4222 2nd Ave NE", citystatezip: "Seattle, WA 98105"},
{ street: "3941 Little Rock", citystatezip: "Antelope, CA 95843"},
{ street: "9 woodleaf", citystatezip: "irvine, ca 92614"},
{ street: "41809 Mission Cielo Ct.", citystatezip: "Fremont, CA 94539"},
{ street: "41809 Mission Cielo Ct", citystatezip: "Fremont, CA 94539"},
{ street: "37659 Sedona Cir", citystatezip: "Murrieta, CA 92563"},
{ street: "2033 Arlington Ter", citystatezip: "Alexandria, Virginia 22303"},
{ street: "3638 Arbor Rd", citystatezip: "Lakewood, CA 90712"},
{ street: "16816 WATSON ROAD", citystatezip: "GUERNEVILLE, CA 95446"},
{ street: "1938 Stonesgate Street", citystatezip: "Westlake Village, CA 91361"},
{ street: "4198 JONES AVENUE", citystatezip: "RIVERSIDE, CA 92505"},
{ street: "525 E. Big Beaver", citystatezip: "Troy, MI 48083"},
{ street: "441 Laurel Avenue", citystatezip: "Millbrae, CA 94030"},
{ street: "1135 East Moor Rd", citystatezip: "Burlingame, CA 94010"},
{ street: "2685 WARBURTON AVENUE", citystatezip: "SANTA CARA, CA 95051"},
{ street: "22 Bay Canyon Road", citystatezip: "Novato, CA 94945"},
{ street: "8462 Lower Scarborough Ct", citystatezip: "San Diego, CA 92127"},
{ street: "4167 Neosho Avenue", citystatezip: "Culver City, CA 90066"},
{ street: "3656 Calle Juego", citystatezip: "Rancho Santa Fe, CA 92091"},
{ street: "2 Downfield Way", citystatezip: "Coto de Caza, CA 92679"},
{ street: "900 LACHMAN LANE", citystatezip: "PACIFIC PALISADES, CA 90272"},
{ street: "2319 Webster Street", citystatezip: "San Francisco, CA 94115"},
{ street: "4194 Bishop Pine Way", citystatezip: "Livermore, CA 94551"},
{ street: "5366 Calumet Ave", citystatezip: "San Diego, Ca 92037"},
{ street: "15011 Las Planideras", citystatezip: "Rancho Santa Fe, Ca 92067"},
{ street: "8911 Mountain Valley Road", citystatezip: "Fairfax Station, VA 22039"},
{ street: "8956 Birchbay Circle", citystatezip: "Lorton, VA 22079"},
{ street: "24371 HILTON WAY", citystatezip: "LAGUN NIGEL, CA 92677"},
{ street: "54 Lagoon Road", citystatezip: "Belvedere Tiburon, CA 94920"},
{ street: "1644 Loch Ness Drive", citystatezip: "Fallbrook, CA 92028"},
{ street: "1264 Via Porovecchio", citystatezip: "San Marcos, Ca 92078"},
{ street: "14457 Eagle River Road", citystatezip: "Eastvale, CA 92880"},
{ street: "455 WEST LIVE OAK DRIVE", citystatezip: "MILL VALLEY, CA 94941"},
{ street: "3601 Hidden Lane #204", citystatezip: "Rolling Hills Estates, CA 90274"},
{ street: "295 Golden Hind Passage", citystatezip: "Corte Madera, CA 94925"},
{ street: "10920 Belcanto Drive", citystatezip: "Rancho Cucamonga, CA 91737"},
{ street: "54 Lagoon Vista Road", citystatezip: "Belvedere Tiburon, CA 94920"},
{ street: "295 Golden Hind Passage", citystatezip: "Corte Madera, CA 94925"},
{ street: "14457 Eagle River Road", citystatezip: "Corona, CA 92880"},
{ street: "630 Fir Park Lane", citystatezip: "Fircrest, WA 98466"},
{ street: "720 S.E. Forest Glenn Rd.", citystatezip: "Estacada, Oregon 97023"},
{ street: "3177 SAN JOSE AVENUE", citystatezip: "SAN FRANCSCO, CA 94112"},
{ street: "11752 Huston st", citystatezip: "Valley Village, CA 91607"},
{ street: "2991 Alexis", citystatezip: "Palo Alto, Ca 94304"},
{ street: "808 Lenzen Ave. #119", citystatezip: "San Jose, Ca 95126"},
{ street: "43 Prospect Avenue", citystatezip: "Sausalito, CA 94965"},
{ street: "43 Prospect Avenue", citystatezip: "Sausalito, CA 94965"},
{ street: "595 E. CARNATION STREET", citystatezip: "PALM SPRINGS, CA 92262"},
{ street: "2005 Dufour Avenue #B", citystatezip: "Redondo Beach, CA 90278"},
{ street: "6834 51st Ave NE", citystatezip: "Seattle, WA 98115"},
{ street: "909 N.PATENCIO ROAD", citystatezip: "PALM SPRINGS, CA 92262"},
{ street: "54840 AVENIDA MARTINEZ", citystatezip: "LA QUINTA, CA 92253"},
{ street: "175 Middlebrook Farm Road", citystatezip: "Wilton, CT 6897"},
{ street: "7857 eienhhower", citystatezip: "Ventura, Ca 93003"},
{ street: "5525 Cango Ave #308", citystatezip: "Woodland Hills, Ca 91367"},
{ street: "3009 Pueblo street", citystatezip: "Carlsbad, Ca 92009"},
{ street: "3009 Pueblo st", citystatezip: "Carlsbad, Ca 92009"},
{ street: "1608 Linda Mere place", citystatezip: "Los Angeles, Ca 92077"},
{ street: "3406 sapphire drive", citystatezip: "Rocklan, Ca 95677"},
{ street: "156 Ridge Road", citystatezip: "Alamo, CA 94507"},
{ street: "20 HARMONY CT", citystatezip: "DANVILLE, CA 94526"},
{ street: "604 16TH AVENUE", citystatezip: "MENLO PARK, CA 94025"},
{ street: "1070 S. Mountain Ave", citystatezip: "Ontario, CA 91762"},
{ street: "16924 Old Colony Way", citystatezip: "Rockville, MD 20853"},
{ street: "365 Mullet Ct", citystatezip: "Foster City, CA 94404"},
{ street: "407 Marview Drive", citystatezip: "Solana Beach, Ca 92075"},
{ street: "631 NEVADA AVENUE", citystatezip: "SAN MATEO, CA 94402"},
{ street: "6212 Payton Way", citystatezip: "Frederick, MD 21703"},
{ street: "2107 Bay Front Terrace", citystatezip: "Annapolis, MD 21409"},
{ street: "4901 Biloxi Ave", citystatezip: "Hollywood, CA 91601"},
{ street: "1038 Brice Road", citystatezip: "Rockville, MD 20852"},
{ street: "5743 Corsa Ave Suite 201", citystatezip: "Westlake Village, CA 91362"},
{ street: "1394 REDSAIL CIRCLE", citystatezip: "THOUSAND OAKS, CA 91361"},
{ street: "215 AVENUE DE MONACO", citystatezip: "CARDIFF, CA 92007"},
{ street: "76 Prospect Street", citystatezip: "Wellesley, MA 2481"},
{ street: "48 Vela Ct", citystatezip: "Coto De Caza, CA 92679"},
{ street: "3003 Longview Drive", citystatezip: "San Bruno, Ca 94066"},
{ street: "1133 CAMBRIDGE ROAD", citystatezip: "BURLINGAME, CA 94010"},
{ street: "22623 CASCADE DRIVE", citystatezip: "CANYON LAKE, CA 92587"},
{ street: "29922 Morongo Place", citystatezip: "Laguna Niguel, CA 92677"},
{ street: "25 White Sail", citystatezip: "Laguna Niguel, CA 92677"},
{ street: "1425 F Street NE", citystatezip: "Washington, DC 20002"},
{ street: "1239 San Dieguito Dr.", citystatezip: "Encinitas, CA 92024"},
{ street: "2767 Secret Lake Lane", citystatezip: "Fallbrook, CA 92028"},
{ street: "161 E Cascade Dr", citystatezip: "Rialto, CA 92376"},
{ street: "949 Fillmore Street", citystatezip: "San Francisco, CA 94117"},
{ street: "1552 S. Camino Real Unit333", citystatezip: "Palm Springs, CA 92264"},
{ street: "3273 California St", citystatezip: "Costa Mesa, CA 92626"},
{ street: "36804 NE Lewisville Hwy", citystatezip: "La Center, WA 98629"},
{ street: "5 WOODRIDGE CT", citystatezip: "REDWOOD CITY, CA 94061"},
{ street: "3292 Arden Way", citystatezip: "Chino Hills, CA 91709"},
{ street: "917 Centro Way", citystatezip: "Mill Valley, CA 94941"},
{ street: "677 South 22nd Street", citystatezip: "San Jose, CA 95116"},
{ street: "10605 Carson Range Rd", citystatezip: "Truckee, CA 96161"},
{ street: "917 Centro Way", citystatezip: "Mill Valley, CA 94941"},
{ street: "675 Mildred Avenue", citystatezip: "Venice, Ca 90291"},
{ street: "1733 41st Street", citystatezip: "Sacremento, CA 95819"},
{ street: "337 MARIN AVENUE", citystatezip: "MILL VALLEY, CA 94941"},
{ street: "296 HILLVIEW AVENUE", citystatezip: "REDWOOD CITY, CA 94062"},
{ street: "23603 Silkwood Ct", citystatezip: "Murrieta, CA 92562"},

	])

puts "Addresses Done"

User.create!([
	{ email: "brad.lookabaugh@1rex.com", password: "123456789", password_confirmation: "123456789", admin: true },
	])
puts "Users Done"

