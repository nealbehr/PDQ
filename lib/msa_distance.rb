########################################################################
# This module holds all of the functions used tin rurality assessment
# Date: 2016/04/25
# Author: Brad
########################################################################
module MsaDistance
  module_function

  # Constants
  PROD_GOOG_API_KEY = "AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko" # Neals
  TEST_GOOG_API_KEY = "AIzaSyCElExJi84Csi1WwouNB1eBn3hKd40dSZ8" # Brads

  # Cities
  # Todo - update values with Brodies results
  RANGES = [
        {city: "Baltimore MD", range: 10000, :loc => "39.18,-76.67"}, 
        {city: "Philadelphia PA", range: 60000, :loc => "39.88,-75.25"}, 
        {city: "Pittsburgh PA", range: 10000, :loc => "40.5,-80.22"}, 
        {city: "Virginia Beach VA", range: 10000, :loc => "36.9,-76.2"}, 
        {city: "Washington DC", range: 100000, :loc => "38.85,-77.04"}, 
        {city: "New York NY", range: 100000, :loc => "40.77,-73.98"}, 
        {city: "Boston MA", range: 30000, :loc => "42.37,-71.03"}, 
        {city: "Providence RI", range: 10000, :loc => "41.73,-71.43"}, 
        {city: "Albany NY", range: 5000, :loc => "42.75,-73.8"}, 
        {city: "Buffalo NY", range: 5000, :loc => "42.93,-78.73"}, 
        {city: "Los Angeles CA", range: 100000, :loc => "34.05,-118.25"}, 
        {city: "Riverside CA", range: 25000, :loc => "33.948,-117.3961"}, 
        {city: "Sacramento CA", range: 34000, :loc => "38.587,-121.351"}, 
        {city: "San Diego CA", range: 75000, :loc => "32.7150,-117.1625"}, 
        {city: "San Francisco CA", range: 75000, :loc => "37.80,-122.27"}, 
        {city: "San Jose CA", range: 75000, :loc => "37.3382,-121.886"}, 
        {city: "Santa Barbara CA", range: 34000, :loc => "34.4258,-119.7142"}, 
        {city: "Monterey CA", range: 8500, :loc => "36.607,-121.892"},
        {city: "Santa Rosa CA", range: 8000, :loc => "38.448,-122.704"},
        {city: "Temecula CA", range: 15000, :loc => "33.540,-117.150"},
        {city: "San Luis Obispo CA", range: 7000, :loc => "35.288,-120.666"},
        {city: "Portland OR", range: 35000, :loc => "45.52,-122.6819"}, 
        {city: "Seattle WA", range: 61000, :loc => "47.6097,-122.3331"},
        {city: "Salem OR", range: 9000, :loc => "44.9421,-123.0254"},
        {city: "Eugene OR", range: 12000, :loc => "44.0582,-123.0672"},
        {city: "Bend OR", range: 5000, :loc => "44.0600,-121.3024"},
        {city: "Redmond OR", range: 3000, :loc => "44.2716,-121.0672"}, 
        {city: "Medford OR", range: 5000, :loc => "42.3411,-122.873"},
        {city: "Ventura CA", range: 10000, :loc => "34.2244,-119.1832"},
        {city: "Bellingham WA", range: 5000, :loc => "48.7545,-122.5068"},
        {city: "Port Orchard WA", range: 7000, :loc => "47.550,-122.6368"},
        {city: "Richmond VA", range: 20000, :loc => "37.5415,-774767"}
      ]

  # State to city groupings
  GROUPINGS = [
    {:states => ["CA"], 
     :cities => ["Los Angeles CA", "Riverside CA", "Sacramento CA",
                 "San Diego CA", "San Francisco CA", "San Jose CA", 
                 "Santa Barbara CA", "Monterey CA","Santa Rosa CA", 
                 "Temecula CA", "San Luis Obispo CA", "Ventura CA"]},
    {:states => ["OR", "WA"], 
     :cities => ["Portland OR", "Seattle WA", "Salem OR", 
                 "Eugene OR", "Bend OR", "Redmond OR", 
                 "Medford OR", "Bellingham WA", "Port Orchard WA"]},
    {:states => ["NY", "MA", "RI", "CT", "VT", "NH", "ME"],
     :cities => ["Boston MA", "New York NY", "Providence RI", 
                 "Albany NY", "Buffalo NY"]},
    {:states => ["NJ", "PA", "RI", "MD", "VA", "DE", "DC"], 
     :cities => ["Baltimore MD", "Philadelphia PA", "Pittsburgh PA", 
                 "Virginia Beach VA", "Washington DC", "New York NY", 
                 "Richmond VA"]}
  ]

  # Updates the output hash with city distance check for the three closest cities
  def msaDistanceCheck(output, address)
    # Get the cities, distances, ranges (returned in array)
    closest_cities, google_url = getCityDistances(address)

    output[:urlsToHit] << google_url # Save url

    # Get output indices and update results
    ind = []
    ind << output[:metricsName].index("Distance from MSA")
    ind << output[:metricsName].index("Second Distance from MSA")
    ind << output[:metricsName].index("Third Distance from MSA")

    # If error occurred
    if closest_msas == "Error Retrieving Distances"
      ind.each do |i|
        output[:metrics][i] = "NA"
        output[:metricsPass][i] = false
        output[:metricsComments][i] = "Distance check failed"
      end
    end

    # Store in outputs
    closest_cities.each_with_index do |c, i|
      output[:metrics][ind[i]] = c[0] # distance
      output[:metricsPass][ind[i]] = (c[0] <= c[2]) # true if distance less than range
      output[:metricsComments][ind[i]] = "Distance in meters must be less than #{c[2]} | #{(i+1).ordinalize} Closest MSA: #{c[1]}" 
    end

    return output
  end

  # Given an address, returns the distance, city, and range of the three closest cities to the address. Output included to store URL
  def getCityDistances(address)
    state = address.citystatezip.split(" ")[-2]

    # Filter on cities
    filtered_groups = GROUPINGS.select { |g| g[:states].include? state}
    cities_to_check = filtered_groups.collect { |f| f[:cities] }.flatten
    
    # Filter on Ranges
    city_ranges = RANGES.select { |r| cities_to_check.include? r[:city] }

    # Get lat/lons
    loc_str = city_ranges.collect { |c| c[:loc] }.join("|")

    # Contruct URL
    base_url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{address.street} #{address.citystatezip}&destinations=#{loc_str}&key=#{TEST_GOOG_API_KEY}"

    # Ping google and parse json
    url = URI.parse(URI.encode(base_url))
    response = Net::HTTP.get(url)
    json_result = JSON.parse(response)

    # Extract distance in meters (if error in data, return error message)
    distances = []
    begin
      json_result["rows"][0]["elements"].each { |r| distances << r["distance"]["value"] }
    rescue StandardError => e
      closest_msas = "Error Retrieving Distances"
      return closest_msas, url.to_s     
    end

    # Find top 3
    closest_msas = []
    3.times do
      min_dist = distances.min()
      min_city = cities_to_check.delete_at(distances.index(min_dist)) # pop min city
      min_radius = city_ranges.select { |r| r[:city] == min_city }[0][:range]
      
      closest_msas << [min_dist, min_city, min_radius] # Store values
      distances.delete(min_dist) # remove minimum distance from array
    end

    return closest_msas, url.to_s
  end

end