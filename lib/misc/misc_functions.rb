########################################################################
# This module holds miscellaneous functions used throughout
# Date: 2016/04/21
# Author: Brad
########################################################################
module MiscFunctions
  module_function

  require 'mixpanel-ruby'
  MIXPANEL_TOKEN = '6d8fc694585f4014626a6708a807ae0a'

  # Function to track run on mixpanel
  def mixPanelTrack(street, citystatezip, product)
    puts "Let's track this..."
    tracker = Mixpanel::Tracker.new(MIXPANEL_TOKEN)

    # Track an event on behalf of user "User1"
    tracker.track('TestUser1', 'getvalues')

    # Send an update to User1's profile
    tracker.track('TestUser2', 'getvalues', {
      'street' => street,
      'citystatezip' => citystatezip,
      'product' => product,
      'event' => 'prequal'
      })

    puts "Shit is tracked"
  end

  # Function to clean the address inputs
  def addressStringClean(s)
    return s if s.nil?
    del_chars = "[]',."
    new_s = URI.unescape(s.to_s.upcase.delete(del_chars).gsub("+"," ").strip)
    return new_s
  end

  # One time script to update the Output data table values with place_ids
  def addGooglePlace
    outputs = Output.all
    cnt = 1

    outputs.each do |i|
      puts cnt if cnt % 10 == 0
      geo_data = GeoFunctions.getGooglePlaceId(i.street, i.citystatezip)
      i.place_id = geo_data[:placeId]
      i.save
      
      # if i.place_id.nil?
      #   geo_data = GeoFunctions.getGooglePlaceId(i.street, i.citystatezip)
      #   i.place_id = geo_data[:placeId]
      #   i.save
      # end
      cnt += 1
    end
  end

end