module PdqEngine
  module_function

  # Settings
  ZILLOW_IND = true
  MLS_IND = false
  FIRST_AM_IND = false
  REASON_CNT = 12
  DECISION_DATA_SOURCE = "Zillow"

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
  def computeDecision(address, params, runId)
    # Start timer
    start_time = Time.now

    # FOR TESTING
    #address.street = MiscFunctions.addressStringClean(address.street)
    #address.citystatezip = MiscFunctions.addressStringClean(address.citystatezip)

    # See if record already exists, if so, exit function
    #output = Output.find_by(street: address.street, citystatezip: address.citystatezip)
    #return nil if (!output.nil? && params[:path] != "gather")

    # Set up storage
    output_data = {:urlsToHit => [], 
                   :runID => runId, 
                   :reason => [nil]*REASON_CNT}

    createEmptyStorage(output_data, "Google")
    createEmptyStorage(output_data, "Census")
    createEmptyStorage(output_data, "Zillow") if ZILLOW_IND
    createEmptyStorage(output_data, "MLS") if MLS_IND
    createEmptyStorage(output_data, "FA") if FIRST_AM_IND

    # ZILLOW INFO GATHERING
    if ZILLOW_IND
      # Get Zillow info
      zillow_data = ZillowApi.collectZillowInfo(address, params)

      # Confirm whether property was found, exit function if not found
      # not_found_check with be a boolean
      not_found_check = zillowNotFoundCheck(output_data, zillow_data[:propRawXml])
      return nil if not_found_check

      # Store Zillow key prop data (kpd)
      zillow_kpd = ZillowApi.getPropertyInfo(zillow_data[:propRawXml])

      # Add zpid to output_data
      output_data[:zpid] = zillow_data[:propRawXml].at_xpath('//zpid').content
    end
    
    # MLS INFO GATHERING
    if MLS_IND
    end

    # FIRST AMERICAN INFO GATHERING
    if FIRST_AM_IND
    end

    # Ping census website and save url
    # WHICH LAT/LON TO USE ONCE WE HAVE MORE DATA SOURCES???
    census_geo_info, census_url = CensusApi.getGeoInfo(zillow_kpd[:lat], zillow_kpd[:lon])

    # Store urls we hit
    output_data[:urlsToHit].push(zillow_data[:urls]).flatten! if ZILLOW_IND
    output_data[:urlsToHit].push(census_url)

    ###### Begin Checks (row in output)
    threads = []
    # Investment Guidelines and Volatility
    threads << Thread.new(output_data) {
      InvestGuidelines.propertyInvestmentGuidelines(output_data, zillow_kpd, census_geo_info, params, "Zillow") if ZILLOW_IND
      Volatility.propertyVolatility(output_data, zillow_kpd, "Zillow")
    }

    threads << Thread.new(output_data) {
      Liquidity.propertyLiquidity(output_data, zillow_data[:compsKeyValues], "Zillow")
      Typicality.propertyTypicality(output_data, zillow_kpd, zillow_data[:compsKeyValues], census_geo_info, "Zillow")
      Typicality.zillowNeighborsValues(output_data, zillow_kpd) if ZILLOW_IND # Typicality Neighbors
    }

    # Rurality (Census data requirement only; needs MSA to run first)
    # MSA Distances (Google only - independent of property data source)
    threads << Thread.new(output_data) {
      distance_info = MsaDistance.msaDistanceCheck(output_data, address)
      Rurality.propertyRurality(output_data, address, census_geo_info, distance_info)
    }

    threads.each { |t| t.join } # join threads

    # InvestGuidelines.propertyInvestmentGuidelines(output_data, zillow_kpd, census_geo_info, params, "Zillow") if ZILLOW_IND
    # distance_info = MsaDistance.msaDistanceCheck(output_data, address)
    # Rurality.propertyRurality(output_data, address, census_geo_info, distance_info)

    # # Liquidity (must run before typicality)
    # Liquidity.propertyLiquidity(output_data, zillow_data[:compsKeyValues], "Zillow")
    # Typicality.propertyTypicality(output_data, zillow_kpd, zillow_data[:compsKeyValues], census_geo_info, "Zillow") # Typicality using comps
    # Typicality.zillowNeighborsValues(output_data, zillow_kpd) if ZILLOW_IND # Typicality Neighbors
    # Volatility.propertyVolatility(output_data, zillow_kpd, "Zillow") # Volatility
    
    output_data[:runTime] = Time.now - start_time
    puts Time.now - start_time
    return output_data, census_geo_info

    # Combine metrics from all data sources data sources
    output_data[:allMetrics] = output.values.collect { |v| v[:metrics] if v.is_a?(Hash) }.compact.flatten << "--End-Metrics--"
    output_data[:allNames] = output.values.collect { |v| v[:metricsNames] if v.is_a?(Hash) }.compact.flatten << "--End-Names--"
    output_data[:allPasses] = output.values.collect { |v| v[:metricsPass] if v.is_a?(Hash) }.compact.flatten << "--End-Passes--"
    output_data[:allComments] = output.values.collect { |v| v[:metricsComments] if v.is_a?(Hash) }.compact.flatten << "--End-Comments--"
    output_data[:allUsages] = output.values.collect { |v| v[:metricsUsage] if v.is_a?(Hash) }.compact.flatten << "--End-Usage--"
    output_data[:allDataSources] = output.values.collect { |v| v[:dataSource] if v.is_a?(Hash) }.compact.flatten

    # Get Decision
    getDecision(output_data, DECISION_DATA_SOURCE)

    # Save output
    saveOutputRecord(address, output_data)
  end


#################################
# Helper functions
#################################
  # Add storage to the hash for the given data source
  def createEmptyStorage(data_hash, data_source)
    data_hash[data_source.to_sym] = {:metrics => [], 
                                     :metricsNames => [], 
                                     :metricsPass => [], 
                                     :metricsComments => [],
                                     :metricsUsage => [],  
                                     :dataSource => []}
  end
  
  def zillowNotFoundCheck(output, zillow_xml_data)
    zpid = zillow_xml_data.at_xpath('//zpid')
    zestimate = zillow_xml_data.at_xpath('//results//result//zestimate//amount')

    # Error check - prop not found - exit function
    if (zpid.nil? || zestimate.nil?)
      output_data[:Zillow][:metricsNames] << "API FAIL"
      output_data[:Zillow][:metrics] << "PROPERTY NOT FOUND"
      output_data[:Zillow][:metricsPass] << false
      output_data[:Zillow][:metricsComments] << "PROPERTY NOT FOUND"
      output_data[:Zillow][:metricsUsage] << "PROPERTY NOT FOUND"
      output_data[:reason] << "Not Found"

      saveOutputRecord(address, output_data)
      return true
    end

    return false
  end

  # Save the output data for a property
  def saveOutputRecord(address, output)
    newOutput = Output.new
    newOutput.street = address.street
    newOutput.citystatezip = address.citystatezip
    newOutput.date = Date.today  
    newOutput.product = params[:product].to_s.upcase
    newOutput.time = output[:runTime].round(2)
    newOutput.runid = output[:runID]
    newOutput.urls = output[:urlsToHit]
    newOutput.reason = output[:reason]
    newOutput.numbers = output[:allMetrics]
    newOutput.names = output[:allNames]
    newOutput.passes = output[:allPasses]
    newOutput.comments = output[:allComments]
    newOutput.usage = output[:allUsages]
    newOutput.data_source = output[:allDataSources] 
    newOutput.zpid = data[:zpid]
    newOutput.save
  end

  # Determine if the property is approved
  def getDecision(output, data_source)
    key = data_source.to_sym

    # Last sold check
    idx = output[key][:metricsNames].index("Last Sold History")
    output[:reason][0] = "Sold too recently" if !output[key][:metricsPass][idx]

    # Rurality Checks
    rs_idx = output[key][:metricsNames].index("Rurality Score")
    vol_idx = output[key][:metricsNames].index("St. Dev. of Historical Home Price")

    if output[:region] == "East"
     reason[1] = "Too rural" if (!output[key][:metricsPass][rs_idx] || !output[key][:metricsPass][vol_idx])    
    end

    if output[:region] == "West"
      reason[1] = "Too rural" if !output[key][:metricsPass][rs_idx]
    end

    # Typicality
    typ_idx = output[key][:metricsUsage].each_index.select { |i| arr[i] == "Typicality" }
    typ_fail_cnt = output[key][:metricsPass][typ_idx].count(false)

    if data_source == "Zillow"
      neigh_idx = output[key][:metricsNames].index("Neighbors available")

      if output[key][:metricsPass][neigh_idx] >= 4
        sqft_idx = output[key][:metricsNames].index("Sqft Typicality - Comps")
        sqfi_nb_idx = output[key][:metricsNames].index("Sqft Typicality - Neighbors")
        est_idx = output[key][:metricsNames].index("Estimate Typicality - Comps")
        est_nb_idx = output[key][:metricsNames].index("Estimate Typicality - Neighbors")
        
        reason[2] = "Atypical property" if typ_fail_cnt >= 3
        reason[2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 65.0 || output[key][:metrics][est_idx] > 65.0)
        reason[2] = "Atypical property" if !output[key][:metricsPass][sqft_idx] && !output[key][:metricsPass][sqfi_nb_idx]
        reason[2] = "Atypical property" if !output[key][:metricsPass][est_idx] && !output[key][:metricsPass][est_nb_idx]
      else
        reason[2] = "Atypical property" if typ_fail_cnt >= 2
        reason[2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 60.0 || output[key][:metrics][est_idx] > 60.0)
      end
    else
      reason[2] = "Atypical property" if typ_fail_cnt >= 2
      reason[2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 60.0 || output[key][:metrics][est_idx] > 60.0)
    end

    # Liquidity (allow one false)
    liq_idx = output[key][:metricsUsage].each_index.select { |i| arr[i] == "Liquidity" }
    reason[3] = "Illiquidity" if output[key][:metricsPass][liq_idx].count(false) >= 2

    # Investment Guidelines
    est_idx = output[key][:metricsNames].index("Estimated Value")
    type_idx = output[key][:metricsNames].index("Property Use")
    build_idx = output[key][:metricsNames].index("Build Date")
    msa_idx = output[key][:metricsNames].index("Pre-approval")

    reason[4] = "out of $ range" if output[key][:metricsPass][est_idx]
    reason[5] = "Not Prop Type" if output[key][:metricsPass][type_idx]
    reason[6] = "New Construction" if output[key][:metricsPass][build_idx]
    reason[7] = "Not in MSAs" if output[key][:metricsPass][msa_idx]

    # Volatility (allow one false)
    vol_idx = output[key][:metricsUsage].each_index.select { |i| arr[i] == "Volatility" }
    reason[8] = "Price Vol" if output[key][:metricsPass][vol_idx].count(false) >= 2

    # Combo Rural (if applicable)
    cr_idx = output[key][:metricsNames].index("Combo Rural")
    reason[9] = "Combo Rural" if !output[key][:metricsPass][cr_idx]

    # Distance
    reason[10] = "MSA Distance" if !output[:Google][:metricsPass].any?

    # Approve if not issues
    reason[11] = "Approved" if reason.compact.size == 0
  end
end