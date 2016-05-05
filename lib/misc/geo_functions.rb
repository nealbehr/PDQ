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
