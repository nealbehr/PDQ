########################################################################
# This module holds all of the functions used in the research controller
# Date: 2016/04/08
# Author: Brad
########################################################################
module ResearchFunctions
	# Load in gems
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'
  require 'mixpanel-ruby'
  require 'httparty'

	# This function takes a PDQ ID as input and returns relevant rurality data in a JSON
	def getRuralityData(prop_data, rurality_names)
		puts "In getRuralityData function"

		# Handle Property not found issues -----------------
  	if prop_data.reason.to_s.delete("[]\"").split(",").map(&:lstrip)[0] == "Not Found"
  	  	results = {:Status => "Property Not Found"}.to_json
  
		# If property ran correctly collect the data
  	else
  		# remove unwanted characters, leading whitespace from names, metrics,
	  	# and passes; separate into an arrays
	  	stripped_names = prop_data.names.to_s.delete("[]\"").split(",").map(&:lstrip) 
	  	stripped_metrics = prop_data.numbers.to_s.delete("[]\"").split(",").map(&:lstrip)
	  	stripped_passes = prop_data.passes.to_s.delete("[]\"").split(",").map(&:lstrip)

	  	# Set up storage
	  	results = Hash.new

	  	# House LocationID
	  	#results['Id'] = prop_data.id
	  	results['Street'] = prop_data.street
	  	results['City-State-Zip'] = prop_data.citystatezip

	  	# Collect variables of interest
	  	rurality_names.each do |x|
	  		tmp_ind = stripped_names.index(x)
	  		results[(x + ' Metric').to_sym] = stripped_metrics[tmp_ind]
	  		results[(x + ' Pass').to_sym] = stripped_passes[tmp_ind]		
	  	end

	  	# Convert to json
	  	results = results.to_json 
		end
		
		return results
	end

	def getMlsProperties(api_token, query_size)
		# Construct URL - including filters
		url = "http://api.mpoapp.com/v1/properties/search?q="
		filters = ['mls.name:sfar AND ',
							'primary.mpoPropType:singleFamily',
							'&from=0&size=' + query_size.to_s]

		filters.each { |s| url += s }
		url += '&api_key=' + api_token.to_s

    #url = "http://api.mpoapp.com/v1/properties/search?q=*"
    puts url
    puts url.inspect

    # Fetch data
    #uri = URI(url)
    uri = URI.parse(URI.encode(url.strip))
    response = Net::HTTP.get(uri)
    json_result = JSON.parse(response)

    # # Set up storage
    mls_props = Hash.new
    listing_results = json_result["results"]

    # Loop over listing results
    cnt = 1
    listing_results.each do |r|
      # Checks:
      # Which price to use: listingPrice, searchPrice or origPrice??
      price = r["primary"]["price"]["searchPrice"]
      prop_type = r["primary"]["mpoPropType"]
      year_built = r["construction"]["yearBuilt"]

      next if (price < 250000 || price > 5000000) # Price range 
      next unless (prop_type == "singleFamily" || prop_type == "condominium") # Property Type
      next if ([Time.now.year.to_i, Time.now.year.to_i-1].include? year_built) # Condition for build date

      # Get address - street and city-state-zip
      address_split = r["primary"]["address"]["mpoAddress"].split(",")
      street = address_split[0]
      csz = [address_split[1], address_split[2]].join(",")[1..-1]

      house_hash = {:street => street,
                    :citystatezip => csz,
                    :price => price,
                    :propType => prop_type,
                    :bed => r["primary"]["interior"]["bed"],
                    :bath => r["primary"]["interior"]["bath"],
                    :propSize => r["primary"]["interior"]["sqFt"],
                    :lon => r["geo"]["lon"],
                    :lat => r["geo"]["lat"],
                    :lotSize => r['lot']["lotSqFt"],
                    :onMarket => r["mls"]["onMarket"],
                    :yearBuilt => year_built,
                    :neighborhood => r["primary"]["mpoNeighborhood"],
                    :mlsId => r["_id"]}
      mls_props[cnt] = house_hash
      cnt += 1
    end

    return mls_props.to_json
	end

  def test_httparty(api_token)
    base_url = "http://api.mpoapp.com/v1/properties/_search"

    # Headers
    headers = Hash.new
    # headers['Authorization'] = api_token
    # headers['Content-Type'] = 'application/json; charset=UTF-8'

    headers = {:Authorization => api_token,
               "Content-Type" => 'application/json; charset=UTF-8'
              }
    
    # Search conditions
    data = Hash.new
    # filters['Authorization'] = api_token # Headers
    # filters['Content-Type'] = 'application/json; charset=UTF-8'

    data['headers'] = headers

    #data['from'] = 0
    #data['size'] = 4
    data['query'] = {:bool => {:must => [{:terms => {"primary.mpoStatus" => ["active"]}},
                                            {:terms => {"primary.mpoPropType" => ["singleFamily"]}},
                                            {:geo_bounding_box => {:geo => {:top_right => {:lat => 37.794728,
                                                                                           :lon => -122.28195},
                                                                            :bottom_left => {:lat => 37.78180,
                                                                                             :lon => -122.501460} 
                                                                            }
                                                                  }
                                          }]
                              }
                    }
    #data['sort'] = {"_created" => {:order => "desc"}}
    puts data
    #response = HTTParty.post(base_url, data)

    #puts response
    return response
  end

end

# ALTERNATIVE CODE TO PARSING THE STREET AND CSZ IN getMlsProperties
# tmp_address = r["primary"]["address"]
# street_items = [tmp_address["streetNum"], 
#                 tmp_address["streetName"], 
#                 tmp_address["streetSuffix"]]

# street = street_items.join(" ")

# csz_items = [tmp_address["city"], 
#              tmp_address["state"], 
#              tmp_address["zipCode"]]
# csz = csz_items.join(",")