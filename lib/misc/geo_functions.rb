########################################################################
# This module holds all of the functions used to compute distances
# between lat/lon coordinates
# Date: 2016/04/25
# Author: Brad
########################################################################
module GeoFunctions
  module_function

  # Constants
  EARTH_RAD_FT = 3959*5280 # ft
  EARTH_RAD_M = EARTH_RAD_FT*(1/3.28084) # meters
  PROD_GOOG_API_KEY = "AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko" # Neals
  TEST_GOOG_API_KEY = "AIzaSyCElExJi84Csi1WwouNB1eBn3hKd40dSZ8" # Brads

  def getGoogleGeoByAddress(street, csz)
    address_str = [street, csz].join(" ")
    base_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{address_str}&key=#{TEST_GOOG_API_KEY}"

    # Get the response
    uri = URI.parse(URI.escape(base_url))
    response = Net::HTTP.get(uri)
    json_result = JSON.parse(response)

    # ERROR CATCH
    return nil if json_result["status"] == "INVALID REQUEST"

    place_results = json_result["results"][0]

    # Define place id
    place_id = place_results["place_id"]

    # Collect unit number (if applicable)
    address_components = json_result["results"][0]["address_components"]
    address_components.each { |c| place_id += "+#{c["long_name"]}" if c["types"][0] == "subpremise" }

    geo_data = {:placeId => place_id,
                :lat => place_results["geometry"]["location"]["lat"],
                :lon => place_results["geometry"]["location"]["lng"],
                :format_add => place_results["formatted_address"]}

    return geo_data
  end

  def getGoogleGeoByPlaceId(placeid)
    # Check if google id appended with unit number
    if placeid.include? "+"
      place_split = placeid.split("+")
      placeid_base = place_split[0]
      unit_num = place_split[1]
      base_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{placeid_base}&key=#{TEST_GOOG_API_KEY}"
    else
      base_url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{placeid}&key=#{TEST_GOOG_API_KEY}"
    end

    # Get the response
    uri = URI.parse(URI.escape(base_url))
    response = Net::HTTP.get(uri)
    json_result = JSON.parse(response)

    # ERROR CATCH
    return nil if json_result["status"] == "INVALID REQUEST"

    place_results = json_result["results"][0]
    format_add_split = place_results["formatted_address"].split(", ")
    add_plus_unit = "#{format_add_split[0]} ##{unit_num}"
    format_add = [add_plus_unit, format_add_split[1..-1]].join(", ")

    geo_data = {:placeId => placeid,
                :lat => place_results["geometry"]["location"]["lat"],
                :lon => place_results["geometry"]["location"]["lng"],
                :format_add => format_add}

    return geo_data
  end  

  # Compute the "as the crow flies" distance between to geo coordinates
  def getDistanceBetween(lat1, lon1, lat2, lon2)
    rad_lat1 = lat1.to_f * Math::PI / 180.0
    rad_lat2 = lat2.to_f * Math::PI / 180.0
    rad_lon1 = lon1.to_f * Math::PI / 180.0
    rad_lon2 = lon2.to_f * Math::PI / 180.0

    dLat = (rad_lat2 - rad_lat1)
    dLon = (rad_lon2 - rad_lon1)

    a = Math.sin(dLat/2.0) * Math.sin(dLat/2.0) + Math.cos(rad_lat1) * Math.cos(rad_lat2) * Math.sin(dLon/2.0) * Math.sin(dLon/2.0)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d = EARTH_RAD_M * c

    return d
  end

  # Compute the distance from a location to vertex of a polygon
  # Source: http://www.mathopenref.com/polygonradius.html
  def calcPolyRadius(in_rad, num_sides)
    x = (Math::PI) / num_sides.to_f # number in radians
    return in_rad.to_f / (Math.cos(x))
  end

  # Get the poly coordinates given poly radius (distance, m), number of sides, and
  # starting point (house location)
  # Source: http://www.movable-type.co.uk/scripts/latlong.html
  # Site to test: http://www.darrinward.com/lat-long/?id=1904412
  def getPolyCoordinates(radius, lat, lon, num_sides)
    # Create array to the radian values of the regular polygon
    rads = (0..2*Math::PI).step((2 * Math::PI) / num_sides.to_f).to_a

    # Compute angular distance (meters)
    ang_dist = (radius.to_f / EARTH_RAD_M.to_f) #*(Math::PI/180.0)
    lat_rad = lat * Math::PI/180.0
    lon_rad = lon * Math::PI/180.0

    # Constants
    a = Math.sin(lat_rad) * Math.cos(ang_dist)
    b = Math.cos(lat_rad) * Math.sin(ang_dist)

    # Loop over radians (clockwise) to compute geo points of the polygon
    points = Array.new
    cnt = 0
    rads.each do |r|
      # new point latitude (in radians)
      new_lat = Math.asin(a +  b * Math.cos(r)) 

      # new point longitude (in radians)
      c = Math.cos(ang_dist) - Math.sin(lat_rad) * Math.sin(new_lat)
      new_lon = lon_rad + Math.atan2(Math.sin(r) * Math.sin(ang_dist) * Math.cos(lat_rad), c)

      # Store (in degrees)
      points[cnt] = {:lat => new_lat*180.0/Math::PI, :lon => new_lon*180.0/Math::PI}
      cnt += 1
    end

    return points
  end

end
