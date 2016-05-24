########################################################################
# This module holds all of the functions used to access the Census API
# Date: 2016/04/20
# Author: Brad
########################################################################
module CensusApi
  module_function

  # Constant
  CENSUS_KEY = ApiTokens.census_key

  # Function to get the census track for the property being analyzed (based on lat/lon)
  def getGeoInfo(lat, lon)
    # Construct url
    base_url = "http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x=#{lon}&y=#{lat}&benchmark=4&vintage=4&format=json"

    # Loop to ping db
    loop_cnt = 0
    while loop_cnt <= 5 do
      puts loop_cnt
      begin
        # Make the request
        url = URI.parse(base_url)
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

        # Read the response, if error, try again
        outputArea = JSON.parse(res.body)

        # Confirm we got the data we need
        census_tract = outputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"]
        census_tract.nil? ? loop_cnt += 1 : loop_cnt = 26   
      rescue
        puts loop_cnt
        loop_cnt += 1
      end
    end

    geo_data = {:state => outputArea.empty? ? nil : outputArea["result"]["geographies"]["Census Tracts"][0]["STATE"],
                :county => outputArea.empty? ? nil : outputArea["result"]["geographies"]["Census Tracts"][0]["COUNTY"],
                :block => outputArea.empty? ? nil : outputArea["result"]["geographies"]["2010 Census Blocks"][0]["BLOCK"],
                :blkgrp => outputArea.empty? ? nil : outputArea["result"]["geographies"]["2010 Census Blocks"][0]["BLKGRP"],
                :fullGeoId => outputArea.empty? ? nil : outputArea["result"]["geographies"]["Census Tracts"][0]["GEOID"],
                :partialGeoId => outputArea.empty? ? nil : outputArea["result"]["geographies"]["Counties"][0]["GEOID"],
                :tract => outputArea.empty? ? nil : outputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"],
                :areaLand => outputArea.empty? ? nil : outputArea["result"]["geographies"]["2010 Census Blocks"][0]["AREALAND"]
    }

    return geo_data, URI.parse(base_url).to_s + " || " + (geo_data[:tract].nil? ? "Fail" : geo_data[:tract])
  end

  # Returns the percent of homes with a given number of bedrooms
  def getBedroomInfo(census_output, num_beds)
    # Construct url
    bd_key = "B25041_007E" if num_beds == 5
    bd_key = "B25041_003E" if num_beds == 1

    base_url = "http://api.census.gov/data/2013/acs5?get=#{bd_key},B25041_001E&for=block+group:#{census_output[:blkgrp]}&in=state:#{census_output[:state]}+county:#{census_output[:county]}+tract:#{census_output[:tract]}&key=#{CENSUS_KEY}"

    # Try to ping api and return results, if error return 0
    begin
      url = URI.parse(base_url)
      req = Net::HTTP::Get.new(url)
      res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

      outputHH = JSON.parse(res.body)
      per_bd = (outputHH[1][0].to_f / outputHH[1][1].to_f)

      return per_bd, url.to_s, outputHH[1][1]

    rescue StandardError => e
      return 0.0, url.to_s, nil
    end
  end

  def getBlockInfo(census_output)
    # Construct url
    base_url = "http://api.census.gov/data/2010/sf1?get=H0030001&for=block:#{census_output[:block]}&in=state:#{census_output[:state]}+county:#{census_output[:county]}+tract:#{census_output[:tract]}&key=#{CENSUS_KEY}"

    begin
      url = URI.parse(base_url)
      req = Net::HTTP::Get.new(url)
      res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

      outputHH = JSON.parse(res.body)
      density = (outputHH[1][0].to_f/(census_output[:areaLand].to_f/2589990.0)).round(2)
      houses = outputHH[1][0].to_f

      return density, houses, url.to_s
    rescue StandardError => e
      return nil, nil, url.to_s
    end
  end
end