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
  CORR_THRES = 0
  RET_VOL_FREQ = "Annual"
  RET_VOL_THRES = 0
  MIN_DATA_PTS = 6

  def propertyVolatility(output, prop_data, data_source)
    # Get price time series depending on data source
    price_data = getZillowVolData(output, prop_data) if data_source.to_s == "Zillow"

    # Perform vol condition checks
    calcStDevPriceDeltas(price_data, output, prop_data[:estimate], data_source)
    calcRangePriceDeltas(price_data, output, prop_data[:estimate], data_source)
    calcStDevPropPrice(price_data, output, prop_data[:estimate], data_source)
    calcCorrelation(price_data, output, data_source, _type = "Returns")
    calcPropReturnVol(price_data, output, data_source)
  end

  # Function to get zillow vol data
  def getZillowVolData(output, prop_data)
    # Get data as json
    begin
      base_url = "http://www.zillow.com/ajax/homedetail/HomeValueChartData.htm?mt=1&zpid=#{prop_data[:zpid]}&format=json"
      url = URI.parse(base_url)
      response = Net::HTTP.get(url)
      json_result = JSON.parse(response)
    rescue StandardError => e
      output[:urlsToHit] = "Error in the Zillow Vol AJAX output"
      return vol_data = {}
    end

    # Save url
    output[:urlsToHit] << url.to_s.gsub(",","THESENTINEL")

    # Set up storage
    accepted_neigh_terms = ["Neighborhood", "Zipcode"]
    differencesInPrices = []
    neighborhoodPrices = []
    propPrices = []

    # Extract graph points: Loop over the json results and collect points for property and neighborhood
    json_result.each do |r|
      item_points = r["points"]
      item_type = r["regionType"]
      item_points.each { |p| propPrices << p["y"] } if item_type == "Home"
      item_points.each { |p| neighborhoodPrices << p["y"] } if accepted_neigh_terms.include? item_type
    end

    # neigh_points = json_result[1]["points"]
    max_ind = [propPrices.length, neighborhoodPrices.length].min()

    # Make sure neighborhood points exist, if not just return home prices
    if max_ind == 0
      output[:urlsToHit] << "Missing property or neighborhood price data preventing differencing"
      return {:propPrices => propPrices, :neighPrices => neighborhoodPrices, :diff => []}
    end

    propPrices = propPrices[0..max_ind-1]
    neighborhoodPrices = neighborhoodPrices[0..max_ind-1]

    for i in 0..max_ind-1
      differencesInPrices << (propPrices[i] - neighborhoodPrices[i])
    end
    vol_data = {:propPrices => propPrices, :neighPrices => neighborhoodPrices, :diff => differencesInPrices}
    return vol_data
  end

  # Calculates the standard deviation of the prop/neighborhood price differences relative to the value of the home
  def calcStDevPriceDeltas(vol_data, output, home_est, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Volatility"
    output[data_source.to_sym][:metricsNames] << "Std. Dev. of Price Deltas"

    # If difference data does not exist
    if vol_data[:diff].length == 0
      output[data_source.to_sym][:metrics] <<"N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "There was an error in computing property/neighborhood price differences"
      return
    end

    # If we are missing property prices
    if vol_data[:propPrices].length == 0
      output[data_source.to_sym][:metrics] <<"N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Missing property price data"
      return
    end

    value = (vol_data[:diff].standard_deviation/home_est).round(3)
    pass = (value < VOL_PRICE_DELTA_THRES)
    comment = "< #{VOL_PRICE_DELTA_THRES} | St. dev. of price differences from neighborhood as a % of estimate"

    # Current Return
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Calculates the range of prop/neighborhood price differences relative to the value of the home
  def calcRangePriceDeltas(vol_data, output, home_est, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Volatility"
    output[data_source.to_sym][:metricsNames] << "Range of Price Deltas"

    # If difference data does not exist
    if vol_data[:diff].length == 0
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "There was an error in computing property/neighborhood price differences"
      return
    end

    # If we are missing property prices
    if vol_data[:propPrices].length == 0
      output[data_source.to_sym][:metrics] <<"N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Missing property price data"
      return
    end

    value = (vol_data[:diff].range/home_est).round(3)
    pass = (value < RANGE_PRICE_DELTA_THRES)
    comment = "< #{RANGE_PRICE_DELTA_THRES} | Total range of price difference from neighborhood as a % of estimate"

    # Current Return
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Calculates the st. dev of the prop price relative to the value of the home
  def calcStDevPropPrice(vol_data, output, home_est, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Volatility"
    output[data_source.to_sym][:metricsNames] << "Std. Dev. of Historical Home Price"

    # If difference data does not exist
    if vol_data[:propPrices].length == 0
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << false
      output[data_source.to_sym][:metricsComments] << "Missing property price data"
      return
    end

    value = (vol_data[:propPrices].standard_deviation/home_est).round(3)
    pass = (value >= VOL_PROP_PRICE_THRES)
    comment = ">= #{VOL_PROP_PRICE_THRES} | St. dev. of historical home price as a % of estimate"

    # Current Return
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Calculates the volatility of the returns of the property price at a set frequency
  def calcPropReturnVol(vol_data, output, data_source)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Volatility"
    output[data_source.to_sym][:metricsNames] << "Return Volatility"

    # If difference data does not exist
    if vol_data[:propPrices].length == 0
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << true # currently not counting in decision
      output[data_source.to_sym][:metricsComments] << "Missing property price data"
      return
    end

    # Transform price series to desired frequency (if necessary)
    rets = computePriceReturns(vol_data[:propPrices])

    # check if there is sufficient data
    if rets.length < 2
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << true # currently not counting in decision
      output[data_source.to_sym][:metricsComments] << "There is insufficient data: Only #{rets.length} obs; #{RET_VOL_FREQ.downcase} freq"
      return
    end

    value = rets.standard_deviation.round(2)
    pass = (value >= RET_VOL_THRES)
    comment = ">= #{RET_VOL_THRES} | Vol of historical #{RET_VOL_FREQ.downcase} returns"

    # Current Return
    output[data_source.to_sym][:metrics] << value
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
    return rets
  end

  # Calculate the correlation between the prop and neighborhood prices
  def calcCorrelation(vol_data, output, data_source, _type)
    output[data_source.to_sym][:dataSource] << data_source.to_s
    output[data_source.to_sym][:metricsUsage] << "Volatility"
    output[data_source.to_sym][:metricsNames] << "Return Correlation of Property and Market"

    # If difference data does not exist
    if vol_data[:neighPrices].length == 0
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << true # currently not counting in decision
      output[data_source.to_sym][:metricsComments] << "Neighborhood prices unavailable"
      return
    end

    # Set up data depending on type of correlation measure
    if _type == "Returns"
      prop_data = computePriceReturns(vol_data[:propPrices])
      neigh_data = computePriceReturns(vol_data[:neighPrices])
    end

    if _type == "Prices"
      prop_data = vol_data[:propPrices]
      neigh_data = vol_data[:neighPrices]
    end

    # check if there is sufficient data
    if prop_data.length < 2
      output[data_source.to_sym][:metrics] << "N/A"
      output[data_source.to_sym][:metricsPass] << true # currently not counting in decision
      output[data_source.to_sym][:metricsComments] << "There is insufficient data: #{prop_data.length} obs (#{_type}; #{RET_VOL_FREQ.downcase} freq)"
      return
    end

    # Compute covariance and correlation
    prods = []
    mean_prop = prop_data.mean
    mean_neigh = neigh_data.mean
    n = prop_data.length
    for i in 0..n-1
      prods << (prop_data[i] - mean_prop) * (neigh_data[i] - mean_neigh)
    end

    cov = prods.sum/(n-1)
    corr = (cov/(prop_data.standard_deviation*neigh_data.standard_deviation)).round(3)

    pass = (corr >= CORR_THRES)
    comment = ">= #{CORR_THRES} | Correlation of historical home and neighborhood prices (not used)"

    # Save Values
    output[data_source.to_sym][:metrics] << corr
    output[data_source.to_sym][:metricsPass] << pass
    output[data_source.to_sym][:metricsComments] << comment
  end

  # Compute returns - length checks to guarantee at least 2 return obs by frequency
  def computePriceReturns(prices)
    rets = []
    rets = prices.map(&:to_f).each_cons(2).map{ |a, b| (b/a - 1) } if (RET_VOL_FREQ == "Monthly" && price.length > 2)
    rets = prices.map(&:to_f).each_cons(4).map { |a| (a[3]/a[0] - 1) } if (RET_VOL_FREQ == "Quarterly" && prices.length > 4)
    rets = prices.map(&:to_f).each_cons(12).map { |a| (a[11]/a[0] - 1) } if (RET_VOL_FREQ == "Annual" && prices.length > 12)
    return rets
  end
end