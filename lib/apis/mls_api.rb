########################################################################
# This module holds all of the functions used to gather mls data
# from the MyPropertyCompany API
# Date: 2016/04/21
# Author: Brad
########################################################################
module MlsApi
  module_function

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

  MLS_TOKEN = "b49bd1d9d1932fc26ea257baf9395d26"

#################################
# Main Data Fetching functions
#################################
  
  # Function needed in pdq
  def getIndividualProperty(street, citystatezip)
  end

  # This function collects the neighbors/comps data in a defined 
  # geographic region for a given house lat/lon and a lookback period 
  # (default = 180 days)
  # Function needed in pdq
  def getCompsData(lat, lon, day_lookback)
    # Pull the list of comps from MLS in the geo bounded polygon
    # (Defaults: shape is an octagon, 1km in any direction, return max 50 props)
    mls_data = getPropertiesByGeo(API_TOKEN, lat, lon, day_lookback, distance = 1000, perimeter_sides = 8, max_count = 100)

    # Pull out results only and set up storage
    comps = JSON.parse(mls_data)["results"]
    comp_data = {:bd => [], 
                 :ba => [], 
                 :sqFt => [], 
                 :lotSize => [], 
                 :value => [], 
                 :sellInfo => []} 

    #test_data = {:propStatus => [], :listingDate => [], :statusDate => [], :sellInfo => [], :onMarketDate => []}

    comps.each_with_index do |c, ind|
      # bedrooms, baths, value
      comp_data[:bd][ind] = c["primary"]["interior"]["bed"]
      comp_data[:ba][ind] = c["primary"]["interior"]["bath"]
      comp_data[:value][ind] = c["primary"]["price"]["listingPrice"]
      comp_data[:sellInfo][ind] = c["mls"]["soldInformation"]

      # lot/home sizes (checks included)
      comp_data[:sqFt][ind] = c["primary"]["interior"]["sqFt"] if c["primary"]["interior"]["sqFt"] > 0
      comp_data[:lotSize][ind] = c['lot']["lotSqFt"] if !c['lot']["lotSqFt"].nil?

      # For testing
      # test_data[:propStatus][ind] = c["primary"]["mpoStatus"]
      # test_data[:listingDate][ind] = c["mls"]["listingDate"]
      # test_data[:statusDate][ind] = c["mls"]["statusDate"]
      # test_data[:onMarketDate][ind] = c["mls"]["onMarketDate"]
      # test_data[:sellInfo][ind] = c["mls"]["soldInformation"]
    end

    return comp_data
  end

  # This funtion queries MLS property data based on specified query filters and output size - can by moved to python
  def getPropertiesByQuery(url)
    # Fetch data
    uri = URI.parse(URI.encode(url.strip))
    response = Net::HTTP.get(uri)
    json_result = JSON.parse(response)

    puts json_result["results"].nil? 

    # Check to make sure we have results
    if json_result["results"].nil?
      return {:status => "No results"}.to_json
    else
      # Return results
      return json_result.to_json
    end

    # Set up storage
    # mls_props = Hash.new
    # listing_results = json_result["results"]

    # # Loop over listing results
    # cnt = 1
    # listing_results.each do |r|      
    #   # Gather data
    #   house_data = getPropertyInfoFromJson(r) # property info  
    #   listing_data = getListingInfoFromJson(r) # listing info
    #   !r["events"].nil? ? event_data = r["events"] : event_data = nil # events info

    #   # Call PDQ to determine if property is pre-qualified
    #   ##############################################################
    #   ###### Placeholder to call get_values (PDQ) on property ######
    #   ##############################################################

    #   # Save results for property
    #   mls_props[cnt] = {:propertyInfo => house_data, 
    #                     :mlsInfo => listing_data,
    #                     :events => event_data}
    #   cnt += 1
    # end

    # # Construct total data hash
    # all_data = Hash.new
    # all_data[:totalNumProperties] = json_result["total"]
    # all_data[:results] = mls_props

    # return all_data.to_json
  end

  # The function returns properties in a geographic bounded polygon
  # Function needed in pdq
  def getPropertiesByGeo(api_token, lat, lon, day_lookback = 180, distance = 1000, perimeter_sides = 8, max_count = 25)
    base_url = "https://api.mpoapp.com/v1/properties/_search?api_key=#{api_token}"

    # Headers
    h = {"Content-Type" => 'application/json; charset=UTF-8', "Cache-Control" => "no-cache"}
    
    # Search conditions
    data = {:from => 0,
            :size => max_count,
            :sort => {:_created => {:order => "desc"}}}

    # Get polygon points
    poly_rad = GeoFunctions.calcPolyRadius(distance, perimeter_sides)
    geo_coords = GeoFunctions.getPolyCoordinates(poly_rad, lat, lon, perimeter_sides)

    # Geo Poly
    geo_poly = {:bool => {:minimum_should_match => 1,
                          :must => [
                                  {:query_string => {:query => "mls.onMarketDate:[" + (Time.now.to_date - day_lookback).to_s + " TO *]"}},
                                  {:terms => {"primary.mpoPropType" => ["singleFamily", "condominium", "loft", "apartment"]}},
                                  {:geo_polygon => {:geo => {:points => geo_coords}}}
                                ]
                        }
                }

    data[:query] = geo_poly
    response = HTTParty.post(base_url, :body => data.to_json, :headers => h)
    return response.to_json
  end

  def testfn(n)
    if n == 2
      return "Done"
    end

    return "Not 2"
  end


#################################
# Helper functions
#################################

  # This function creates the mls json url call based on specified filters and output size - can remain in case
  def createMlsUrl(api_token, query_filters, query_size = 500)
    # Construct URL - including filters
    url = "https://api.mpoapp.com/v1/properties/search?q="

    # Add on filters
    cnt = 0
    query_filters.each  do |item, cond|
      if (cnt == query_filters.size - 1)
        url += "#{item}:#{cond}"
      else
        url += "#{item}:#{cond} AND "
      end
      cnt += 1
    end

    # Add on query limit (if applicable)
    url += "&from=0&size=#{query_size}" if !query_size.nil?

    # Add on API key
    url += "&sort=mls.onMarketDate:desc&api_key=#{api_token}"
    #puts url.inspect
    return url
  end

  # This function is used in the getMlsProperties function to pull property 
  # info from the MLS API - can be deleted
  def getPropertyInfoFromJson(r)
    # Get address - street and city-state-zip
    address_split = r["primary"]["address"]["mpoAddress"].split(",")
    street = address_split[0]
    csz = [address_split[1], address_split[2]].join(",")[1..-1]

    # Add unit number to the street address if it exists
    if !r['primary']['address']['unitNum'].nil?
      street += " Unit " + r['primary']['address']['unitNum']
    end

    # Store Property information
    house_hash = {:street => street,
                  :citystatezip => csz,
                  :listPrice => r["primary"]["price"]["listingPrice"],
                  :origPrice => r["primary"]["price"]["origPrice"],
                  :priceRedux => r["primary"]["price"]["priceReduction"],
                  :propertyType => r["primary"]["mpoPropType"],
                  :bed => r["primary"]["interior"]["bed"],
                  :bath => r["primary"]["interior"]["bath"],
                  :propertySize => r["primary"]["interior"]["sqFt"],
                  :lon => r["geo"]["lon"],
                  :lat => r["geo"]["lat"],
                  :lotSize => r['lot']["lotSqFt"],
                  :yearBuilt => r["construction"]["yearBuilt"],
                  :neighborhood => r["primary"]["mpoNeighborhood"]}
    return house_hash
  end

  # This function is used in the getMlsProperties function to pull office, agent 
  # data, and MLS info from the MLS API - can be deleted
  def getListingInfoFromJson(r)
    # If office data is present, extract it
    pl_office_data = Array.new(3) # Primary listing office
    if !r["offices"].nil?
      pl_office_hash = r["offices"]["listingOffices"][0]
      pl_office_city = pl_office_hash["address"]["city"]
      pl_office_state = pl_office_hash["address"]["state"]
      pl_office_zip = pl_office_hash["address"]["zip"]

      pl_office_data[0] = pl_office_hash["officeName"]
      pl_office_data[1] = pl_office_hash["address"]["fullStreetAddress"]
      pl_office_data[2] = [[pl_office_city, pl_office_state].join(", "), pl_office_zip].join(" ")
    else
      puts "No Office(s) for Listing"
    end

    # If agent data is present, extract it (usually is if office data available)
    pl_agent_data = Array.new(6) # First listing agent
    if !r["agents"].nil?
      pl_agent_hash = r["agents"]["listingAgents"][0]
      pl_agent_data[0] = pl_agent_hash["name"]["last"]
      pl_agent_data[1] = pl_agent_hash["name"]["first"]
      pl_agent_data[2] = pl_agent_hash["contact"]["officePhone"]
      pl_agent_data[4] = pl_agent_hash["contact"]["email"]
    else
      puts "No Agent for Listing"
    end

    # MLS Data
    onMktDate = r["mls"]["onMarketDate"]
    listingDate = r["mls"]["listingDate"]
    mlsId = r["mls"]["mlsId"]

    # Store MLS information and return it
    mls_hash = {:pdqResult => 0,
                :onMarketDate => onMktDate,
                :listingDate => listingDate,
                :listingOfficeName => pl_office_data[0],
                :listingOfficeStreet => pl_office_data[1],
                :listingOfficeCSZ => pl_office_data[2],
                :listingAgentLastName => pl_agent_data[0],
                :listingAgentFirstName => pl_agent_data[1],
                :listingAgentWorkPhone => pl_agent_data[2],
                :listingAgentEmail => pl_agent_data[4],
                :mlsId => mlsId}
    return mls_hash
  end

end