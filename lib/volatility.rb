########################################################################
# This module holds all of the functions used for volatility
# Date: 2016/05/03
# Author: Brad
########################################################################
module Volatility
  module_function

  # Constants
  VOL_PRICE_DELTA_THRES = 0.25
  RANGE_PRICE_DELTA_THRES = 0.80
  VOL_PROP_PRICE_THRES = 0.08
  CORR_THRES = 0.5

  # Zillow Volatility Calculation
  def getZillowVolData(output, prop_data)
    # Get data as json
    begin
      base_url = "http://www.zillow.com/ajax/homedetail/HomeValueChartData.htm?mt=1&zpid=#{prop_data[:zpid]}&format=json"
      url = URI.parse(base_url)
      response = Net::HTTP.get(url)
      json_result = JSON.parse(response)
    rescue StandardError => e
      output[:urlsToHit] = "Error in the AJAX output"
      return vol_data = {}
    end

    # Save url
    output[:urlsToHit] << url.to_s.gsub(",","THESENTINEL")

    # Set up storage
    differencesInPrices = []
    neighborhoodPrices = []
    propPrices = []

    # Extract graph points
    prop_points = json_result[0]["points"]

    # Make sure neighborhood points exist, if not just return home prices
    if json_result[].length < 2
      prop_points.each { |p| propPrices << p["y"] }
      output[:urlsToHit] << "Issues with neighborhood and deltas"
      return {:propPrices => propPrices}
    end

    neigh_points = json_result[1]["points"]
    max_ind = [prop_points.length, neigh_points.length].min()

    for i in 0..max_ind-1
      propPrices << prop_points[i]["y"]
      neighborhoodPrices << neigh_points[i]["y"]
      differencesInPrices << prop_points[i]["y"] - neigh_points[i]["y"]
    end
    vol_data = {:propPrices => propPrices, :neighPrices => neighborhoodPrices, :diff => differencesInPrices}
    return vol_data
  end

  # Calculates the standard deviation of the prop/neighborhood price differences relative to the value of the home
  def calcStDevPriceDeltas(vol_data, output, home_est)
    ind = output[:metricsName].index("Std. Dev. of Price Deltas")

    # If difference data does not exist
    if vol_data[:diff].nil?
      output[:metrics][ind] = "Unavailable"
      output[:metricsPass][ind] = false
      output[:metricsComments][ind] = "There was an error"
      return output
    end

    value = (vol_data[:diff].standard_deviation/home_est).round(3)
    pass = value < VOL_PRICE_DELTA_THRES)
    comment = "< #{VOL_PRICE_DELTA_THRES} || Standard Deviation of price differences from neighborhood as a percentage of overall estimate"

    # Current Return
    output[:metrics][ind] = value
    output[:metricsPass][ind] = pass
    output[:metricsComments][ind] = comment

    # return [value, pass, comment]
    return output
  end

  # Calculates the range of prop/neighborhood price differences relative to the value of the home
  def calcRangePriceDeltas(vol_data, output, home_est)
    ind = output[:metricsName].index("Range of Price Deltas")

    # If difference data does not exist
    if vol_data[:diff].nil?
      output[:metrics][ind] = "Unavailable"
      output[:metricsPass][ind] = false
      output[:metricsComments][ind] = "There was an error"
      # return ["Unavailable", false, "There was an error"]
      return output
    end

    value = (vol_data[:diff].range/home_est).round(3)
    pass = value < RANGE_PRICE_DELTA_THRES)
    comment = "< #{RANGE_PRICE_DELTA_THRES} || Total range of price difference from neighborhood as a percentage of overall estimate"

    # Current Return
    output[:metrics][ind] = value
    output[:metricsPass][ind] = pass
    output[:metricsComments][ind] = comment

    # return [value, pass, comment]
    return output
  end

  # Calculates the st. dev of the prop price relative to the value of the home
  def calcStDevPropPrice(vol_data, output, home_est)
    ind = output[:metricsName].index("Std. Dev. of Historical Home Price")

    # If difference data does not exist
    if vol_data[:propPrices].nil?
      output[:metrics][ind] = "Unavailable"
      output[:metricsPass][ind] = false
      output[:metricsComments][ind] = "There was an error"
      # return ["Unavailable", false, "There was an error"]
      return output
    end

    value = (vol_data[:propPrices].standard_deviation/home_est).round(3)
    pass = value >= VOL_PROP_PRICE_THRES)
    comment = ">= #{VOL_PROP_PRICE_THRES} || Standard Deviation of historical home price as a percentage of overall estimate"

    # Current Return
    output[:metrics][ind] = value
    output[:metricsPass][ind] = pass
    output[:metricsComments][ind] = comment

    # return [value, pass, comment]
    return output
  end

  # Calculate the correlation between the prop and neighborhood prices
  def calcCorrelation(vol_data)
    # If difference data does not exist
    return ["Unavailable", false, "There was an error"] if vol_data[:neighPrices].nil?

    # compute covariance and correlation
    prods []
    mean_prop = vol_data[:propPrices].mean()
    mean_neigh = vol_data[:neighPrices].mean()
    n = vol_data[:propPrices].length
    for i in 0..n-1
      prods << (vol_data[:propPrices][i] - mean_prop) * (vol_data[:neighPrices][i] - mean_neigh)
    end

    cov = prods.sum()/(n-1)
    corr = (cov/(vol_data[:propPrices].standard_deviation*vol_data[:neighPrices].standard_deviation)).round(3)

    pass = value >= CORR_THRES)
    comment = ">= #{CORR_THRES} || Correlation of historical home and neighborhood prices"

    return [value, pass, comment]
  end   

end