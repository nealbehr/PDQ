module PdqValuesAggregator
  module_function

  # Settings
  ZILLOW_IND = true
  MLS_IND = false
  FIRST_AM = false

  # Pre-defined current metric names and usage
  metric_usage = ["Price Range",
                  "MSA Check",
                   3.times.collect { "Liquidity" },
                  11.times.collect { "Typicality" },
                  "Recent Sale",
                  "Property Type",
                  "New Construction",
                  6.times.collect { "Rurality" },
                  3.times.collect { "MSA Dist"},
                  "Combo Rural",
                  3.times.collect { "Volatility" },
                  "--End-Usage--"].flatten
  metric_names = ["Estimated Value",
                  "Pre-approval",
                  "Comps Count",
                  "Comps Recency",
                  "Comps Score",
                  "Properties Count",
                  "Bedrooms Typicality",
                  "SqFt Typicality - Comps",
                  "Estimate Typicality - Comps",
                  "Lot Size Typicality - Comps",
                  "Comps Distance",
                  "Comps Nearby",
                  "Neighbors Available",
                  "Estimate Typicality - Neighbors",
                  "Bedrooms Typicality - Neighbors",
                  "SqFt Typicality - Neighbors",
                  "Last Sold History",
                  "Property Type",
                  "Build Date",
                  "Urban Density",
                  "Census Tract Density",
                  "Surrounding Census Tract Density",
                  "Census Block Density",
                  "Census Block Houses",
                  "Rurality Score",
                  "Distance from MSA",
                  "Second Distance from MSA",
                  "Third Distance from MSA",
                  "Combo Rural",
                  "Std. Dev. of Price Deltas",
                  "Range of Price Deltas",
                  "Std. Dev. of Historical Home Price",
                  "Schools",
                  "--End-Names--"]

#################################
# Main function
#################################
  def computePdqValues(address, params, runId)
    # See if record already exists, if so, exit function
    output = Output.find_by(street: address.street, citystatezip: address.citystatezip)
    return nil if (!output.nil? && params[:path] != "gather")

    # Set up storage
    output_data = Hash.new
    createEmptyStorage(output_data, "zillow", runId) if ZILLOW_IND
    createEmptyStorage(output_data, "mls", runId) if MLS_IND
    createEmptyStorage(output_data, "fa", runId) if FIRST_AM

    # ZILLOW INFO GATHERING
    # Get Zillow info
    zillow_data = ZillowApi.collectZillowInfo(address, params)

    # Confirm whether property was found, exit function if not found
    # not_found_check with be a boolean
    not_found_check = zillowNotFoundCheck(output_data, zillow_data[:propRawXml])
    return nil if not_found_check

    # Store Zillow key prop data (kpd)
    z_kpd = ZillowApi.getPropertyInfo(zillow_data[:propRawXml])






    # Ping census website and save url
    outputArea, census_tract_url = CensusApi.getOutputArea(key_prop_data[:lat], key_prop_data[:lon])
    output_data[:urlsToHit].push(census_tract_url)






    # MLS INFO GATHERING
    # FIRST AMERICAN INFO GATHERING
    

    ###### Begin Checks (row in output)
    InvestGuidelines.propertyValueCheck(output_data, key_prop_data)
    InvestGuidelines.propertyMsaCheck(output_data, key_prop_data)
    InvestGuidelines.propertyRecentSalesCheck(output_data, key_prop_data, params)
    InvestGuidelines.propertyTypeCheck(output_data, key_prop_data)
    InvestGuidelines.propertyBuildYearCheck(output_data, key_prop_data)


    # Liquidity (must run before typicality)
    Liquidity.zillowLiquidity(output_data, zillow_data[:compsKeyValues])

    # Typicality using comps
    Typicality.zillowTypicality(output_data, key_prop_data, zillow_data[:compsKeyValues], outputArea)

    # Typicality Neighbors
    Typicality.zillowNeighborsValues(output_data, key_prop_data)




    # MSA Distances
    MsaDistance.msaDistanceCheck(output_data, address)


    # Schools
    idx = output_data[:metricNames].index("Schools")
    output_data[:metrics][idx] = 0
    output_data[:metricsPass] = false
    output_data[:metricsComments] = ">= 3.5 || Average school rating across 0"

    # End Values
    output_data[:metrics] << "--End-Metrics--"
    output_data[:metricsPass] << "--End-Passes--"
    output_data[:metricsComments] << "--End-Comments--"

    # Get Decision

    # Save output

  end



  def testfn(h)
    h[:value] << "new value"
  end





#################################
# Helper functions
#################################
  # Add storage to the hash for the given data source
  def createEmptyStorage(data_hash, data_source, runId)
    data_hash[data_source.to_sym] = {:metrics => [], 
                                     :metricsNames => [], 
                                     :metricsPass => [], 
                                     :metricsComments => [],
                                     :metricsUsage => [], 
                                     :urlsToHit => [], 
                                     :reason => [],
                                     :dataSource => [], 
                                     :runID => runId}
  end
  
  def zillowNotFoundCheck(output, zillow_xml_data)
    output_data[:zpid] = zillow_xml_data.at_xpath('//zpid')
    zestimate = zillow_xml_data.at_xpath('//results//result//zestimate//amount')

    # Error check - prop not found - exit function
    if (output_data[:zpid].nil? || zestimate.nil?)
      output_data[:metricsNames] << "API FAIL"
      output_data[:metrics] << "PROPERTY NOT FOUND"
      output_data[:metricsPass] << false
      output_data[:metricsComments] << "PROPERTY NOT FOUND"
      output_data[:metricsUsage] << "PROPERTY NOT FOUND"
      output_data[:reason] << "Not Found"

      saveOutputRecord(address, output_data)
      return true
    end

    return false
  end

  # Save the output data for a property
  def saveOutputRecord(address, data)
    newOutput = Output.new
    newOutput.street = address.street
    newOutput.citystatezip = address.citystatezip
    newOutput.names = data[:metricsNames]
    newOutput.numbers = data[:metrics]
    newOutput.passes = data[:metricsPass]
    newOutput.urls = data[:urlsToHit]
    newOutput.reason = data[:reason]
    newOutput.comments = data[:metricsComments]
    newOutput.usage = data[:metricsUsage]
    newOutput.zpid = data[:zpid]
    newOutput.runid = data[:runID]
    #newOutput.time = (Time.now-@startTime-@sectionTimes.inject(:+)).round
    newOutput.date = Date.today  
    newOutput.product = params[:product].to_s.upcase
    newOutput.save
  end


  def getDecision(output)
    # Last sold check
    idx = output[:metricsNames].index("Last Sold History")
    if !output[:metricsPass][idx]
      output[:reason][0] == "Sold too recently"
    end


  end
end