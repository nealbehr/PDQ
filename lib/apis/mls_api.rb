########################################################################
# This module holds all of the functions used to gather mls data
# from the MyPropertyCompany API
# Date: 2016/04/21
# Author: Brad
########################################################################
module MlsApi
  module_function

  # Gems
  require 'street_address'

  # Constants
  MLS_TOKEN = ApiTokens.mls_key
  DAY_LOOK = 180

#################################
# Main Data Fetching functions
#################################
  def collectMlsInfo(address, params)
    # Set up storage
    mls_info = Hash.new
    urls = []

    # Get the individual property data
    prop_result, payload_request = searchIndividualProperty(address)
    urls << payload_request

    # If no property found, return empty hash
    if prop_result["message"] == "No properties found."
      mls_info[:propResult] = "No properties found."
      mls_info[:propCompsData] = nil
      return mls_info, urls
    end

    # Take the top result
    mls_info[:propResult] = prop_result["results"][0]

    # Get comps
    prop_lat = mls_info[:propResult]["geo"]["lat"]
    prop_lon = mls_info[:propResult]["geo"]["lon"]

    comps_result, payload_request = getCompsData(prop_lat, prop_lon)
    urls << payload_request

    mls_info[:compsData] = comps_result
    mls_info[:urls] = urls

    return mls_info
  end

  # Get the key property values
  def getPropertyInfo(mls_prop_result)
    # Get objects (or nil if not present)
    estimate = mls_prop_result["primary"]["price"]["listingPrice"]
    state = mls_prop_result["primary"]["address"]["state"]
    zipCode = mls_prop_result["primary"]["address"]["zipCode"]
    propType = mls_prop_result["primary"]["mpoPropType"]
    buildYear = mls_prop_result["construction"]["yearBuilt"]
    lat = mls_prop_result["geo"]["lat"]
    lon = mls_prop_result["geo"]["lon"]
    bd = mls_prop_result["primary"]["interior"]["bed"]

    full = mls_prop_result["primary"]["interior"]["bath"]
    three_qrt = mls_prop_result["primary"]["interior"]["threeQtrBath"].nil? ? 0 : mls_prop_result["primary"]["interior"]["threeQtrBath"] * 0.75
    qrt = mls_prop_result["primary"]["interior"]["qtrBath"].nil? ? 0 : mls_prop_result["primary"]["interior"]["threeQtrBath"] * 0.25
    ba = full + three_qrt + qrt

    propSqFt = mls_prop_result["primary"]["interior"]["sqFt"]
    lotSqFt = mls_prop_result['lot']["lotSqFt"]

    # Extract data if not nil
    key_prop_data = {
      :estimate => estimate.nil? ? nil : estimate.to_f,
      :state => state.nil? ? nil : state.to_s,
      :zipCode => zipCode.nil? ? nil : zipCode.to_s,
      :propType => propType.nil? ? nil : propType.to_s,
      :buildYear => buildYear.nil? ? nil : buildYear.to_s,
      :lat => lat.nil? ? nil : lat,
      :lon => lon.nil? ? nil : lon,
      :bd => bd.nil? ? nil : bd.to_i,
      :ba => ba.nil? ? nil : ba.to_f,
      :propSqFt => propSqFt.nil? ? nil : propSqFt.to_f,
      :lotSqFt => lotSqFt.nil? ? nil : lotSqFt.to_f,
    }
    return key_prop_data
  end

  # Search for individual property in MLS by address
  def searchIndividualProperty(address)
    address_items = StreetAddress::US.parse([address.street, address.citystatezip].join(" "))
    # address_items = StreetAddress::US.parse("140 OCEAN AVENUE SAN FRANCISCO CA 94112")

    match_terms = []
    match_terms << {:match => {"primary.address.zipCode" => address_items.postal_code.capitalize}}
    match_terms << {:match => {"primary.address.state" => address_items.state}}
    match_terms << {:match => {"primary.address.streetNum" => address_items.number.capitalize}}

    # Need to capitalize each word
    city_terms = address_items.city.split(" ").collect { |c| c.capitalize }.join(" ")
    match_terms << {:match => {"primary.address.city" => city_terms}}

    # Need to capitalize each word
    street_name_terms = address_items.street.split(" ").collect { |c| c.capitalize }.join(" ")
    match_terms << {:match => {"primary.address.streetName" => street_name_terms}}
    
    # Street type regex - just use the first letter in the suffix
    if !address_items.street_type.nil?
      street_type_regex = [address_items.street_type.capitalize[0], ".+"].join()
      match_terms << {:regexp => {"primary.address.streetSuffix" => street_type_regex}}
    end

    # Unit number (if applicable)
    match_terms << {:match => {"primary.address.unitNum" => address_items.unit}} unless address_items.unit.nil?

    # url, headers, query
    base_url = "https://api.mpoapp.com/v1/properties/_search?api_key=#{MLS_TOKEN}"
    h = {"Content-Type" => 'application/json; charset=UTF-8', "Cache-Control" => "no-cache"}
    data = {:from => 0, :size => 10}
    data[:query] = {:bool => {:minimum_should_match => 1, :must => [match_terms]}}

    response = HTTParty.post(base_url, :body => data.to_json, :headers => h)
    json_result = JSON.parse(response.to_json)
    return json_result, data.to_json
  end

  # This function collects the neighbors/comps data in a defined 
  # geographic region for a given house lat/lon and a lookback period 
  # (default = 180 days)
  def getCompsData(lat, lon, day_lookback = DAY_LOOK)
    # Pull the list of comps from MLS in the geo bounded polygon
    # (Defaults: shape is an octagon, 1km in any direction, return max 50 props)
    mls_data, payload_request = getPropertiesByGeo(MLS_TOKEN, lat, lon, day_lookback, distance = 1000, perimeter_sides = 8, max_count = 100)

    # Pull out results only and set up storage
    comps = JSON.parse(mls_data)["results"]
    comp_data = {:count => comps.size,
                 :bds => [], 
                 :bas => [], 
                 :propSqFts => [], 
                 :lotSizes => [], 
                 :estimates => [], 
                 :sellInfo => [],
                 :lats => [],
                 :lons => []
               } 

    comps.each_with_index do |c, ind|
      # bedrooms, baths, value
      comp_data[:bds][ind] = c["primary"]["interior"]["bed"]

      # bath count
      full = c["primary"]["interior"]["bath"]
      three_qrt = c["primary"]["interior"]["threeQtrBath"].nil? ? 0 : c["primary"]["interior"]["threeQtrBath"] * 0.75
      qrt = c["primary"]["interior"]["qtrBath"].nil? ? 0 : c["primary"]["interior"]["threeQtrBath"] * 0.25

      comp_data[:bas][ind] = full + three_qrt + qrt
      comp_data[:estimates][ind] = c["primary"]["price"]["listingPrice"]
      comp_data[:sellInfo][ind] = c["mls"]["soldInformation"]
      comp_data[:lats][ind] = c["geo"]["lat"]
      comp_data[:lons][ind] = c["geo"]["lon"]

      # lot/home sizes (checks included)
      comp_data[:propSqFts][ind] = c["primary"]["interior"]["sqFt"] if c["primary"]["interior"]["sqFt"] > 0
      comp_data[:lotSizes][ind] = c['lot']["lotSqFt"] if !c['lot']["lotSqFt"].nil?
    end

    return comp_data, payload_request
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
    data = {:from => 0, :size => max_count, :sort => {:_created => {:order => "desc"}}}

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
    return response.to_json, data.to_json
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