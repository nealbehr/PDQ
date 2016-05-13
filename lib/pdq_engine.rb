module PdqEngine
  module_function

  # Settings
  ZILLOW_IND = true
  MLS_IND = false
  FIRST_AM_IND = false
  REASON_CNT = 12
  DECISION_DATA_SOURCE = "Zillow"
  DAILY_CNT_THRES = 400

#################################
# Main function
#################################
  def computeDecision(address, params, runId)
    # Start timer
    start_time = Time.now

    # Check property counter - exit process if we have exceed the limit
    daily_pdq_cnt = Output.where("runid LIKE ?", "%#{Time.now.to_date}").length
    return nil if daily_pdq_cnt > DAILY_CNT_THRES

    # Clean the address strings
    address.street = MiscFunctions.addressStringClean(address.street)
    address.citystatezip = MiscFunctions.addressStringClean(address.citystatezip)

    # Get Google place id
    goog_geo_data = GeoFunctions.getGooglePlaceId(address.street, address.citystatezip)

    # See if record already exists, if so, exit function
    # output = Output.find_by(place_id: goog_geo_data[:placeId])
    output = Output.find_by(street: address.street, citystatezip: address.citystatezip)
    return nil if (!output.nil? && params[:path] != "gather")

    # Set up storage
    output_data = {:urlsToHit => [], 
                   :runID => runId,
                   :placeId => goog_geo_data[:placeId],
                   :reason => [nil]*REASON_CNT}
    createEmptyStorage(output_data, "Google")
    createEmptyStorage(output_data, "Census")
    createEmptyStorage(output_data, "Zillow") if ZILLOW_IND
    createEmptyStorage(output_data, "MLS") if MLS_IND
    createEmptyStorage(output_data, "FA") if FIRST_AM_IND

    # output_data[:lat] = goog_geo_data[:lat]
    # output_data[:lon] = goog_geo_data[:lon]

    # ZILLOW INFO GATHERING
    if ZILLOW_IND
      # Get Zillow info
      zillow_data = ZillowApi.collectZillowInfo(address, params)

      # Confirm whether property was found, exit function if not found
      # not_found_check with be a boolean
      not_found_check = zillowNotFoundCheck(output_data, zillow_data[:propRawXml], address, params)
      return nil if not_found_check

      # Store Zillow key prop data (kpd)
      zillow_kpd = ZillowApi.getPropertyInfo(zillow_data[:propRawXml])

      # Add zpid to output_data
      output_data[:zpid] = zillow_data[:propRawXml].at_xpath('//zpid').content
    end
    
    # MLS INFO GATHERING
    if MLS_IND
      if address.citystatezip.include? "SAN FRANCISCO"
        mls_data = MlsApi.collectMlsInfo(address, params)

        # Store Key Mls Data
        mls_kpd = MlsApi.getPropertyInfo(mls_data[:propResult])
      end
    end

    # FIRST AMERICAN INFO GATHERING
    if FIRST_AM_IND
    end

    # Ping census website and save url
    census_geo_info, census_url = CensusApi.getGeoInfo(goog_geo_data[:lat], goog_geo_data[:lon])

    # Store urls we hit
    output_data[:urlsToHit].push(zillow_data[:urls]).flatten! if ZILLOW_IND
    output_data[:urlsToHit].push(census_url)

    ###### Begin Checks (row in output)

    # DATA SOURCE INDEPENDENT
    distance_info = MsaDistance.msaDistanceCheck(output_data, address)
    Rurality.propertyRurality(output_data, address, census_geo_info, distance_info)

    # ZILLOW
    InvestGuidelines.propertyInvestmentGuidelines(output_data, zillow_kpd, census_geo_info, params, "Zillow") if ZILLOW_IND
    Liquidity.propertyLiquidity(output_data, zillow_data[:compsKeyValues], "Zillow") if ZILLOW_IND # Liquidity (must run before typicality)
    Typicality.propertyTypicality(output_data, zillow_kpd, zillow_data[:compsKeyValues], census_geo_info, "Zillow") if ZILLOW_IND # Typicality using comps
    Typicality.zillowNeighborsValues(output_data, zillow_kpd) if ZILLOW_IND # Typicality Neighbors
    Volatility.propertyVolatility(output_data, zillow_kpd, "Zillow") if ZILLOW_IND # Volatility

    # MLS
    if address.citystatezip.include? "SAN FRANCISCO"
      InvestGuidelines.propertyInvestmentGuidelines(output_data, mls_kpd, census_geo_info, params, "MLS") if MLS_IND
      Liquidity.propertyLiquidity(output_data, mls_data[:compsData], "MLS") if MLS_IND # Liquidity (must run before typicality)
      Typicality.propertyTypicality(output_data, mls_kpd, mls_data[:compsData], census_geo_info, "MLS") if MLS_IND # Typicality using comps
    end

    # output_data[:runTime] = Time.now - start_time
    # puts Time.now - start_time
    # return output_data, mls_data, mls_kpd
    # return output_data

    # Get Decision
    getDecision(output_data, DECISION_DATA_SOURCE)

    # Combine metric data from all sources
    combineMetricOutputs(output_data)

    # Save time
    output_data[:runTime] = Time.now - start_time

    # Save output
    saveOutputRecord(address, output_data, params)

    # Save comps
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

  # Combine metrics from all data sources data sources
  def combineMetricOutputs(output)
    output[:allMetrics] = output.values.collect { |v| v[:metrics] if v.is_a?(Hash) }.compact.flatten << "--End-Metrics--"
    output[:allNames] = output.values.collect { |v| v[:metricsNames] if v.is_a?(Hash) }.compact.flatten << "--End-Names--"
    output[:allPasses] = output.values.collect { |v| v[:metricsPass] if v.is_a?(Hash) }.compact.flatten << "--End-Passes--"
    output[:allComments] = output.values.collect { |v| v[:metricsComments] if v.is_a?(Hash) }.compact.flatten << "--End-Comments--"
    output[:allUsages] = output.values.collect { |v| v[:metricsUsage] if v.is_a?(Hash) }.compact.flatten << "--End-Usage--"
    output[:allDataSources] = output.values.collect { |v| v[:dataSource] if v.is_a?(Hash) }.compact.flatten
  end
  
  # If relying on Zillow - save property not found
  def zillowNotFoundCheck(output, zillow_xml_data, address, params)
    zpid = zillow_xml_data.at_xpath('//zpid')
    zestimate = zillow_xml_data.at_xpath('//results//result//zestimate//amount')

    # Error check - prop not found - exit function
    if (zpid.nil? || zestimate.nil?)
      output[:Zillow][:metricsNames] << "API FAIL"
      output[:Zillow][:metrics] << "PROPERTY NOT FOUND"
      output[:Zillow][:metricsPass] << false
      output[:Zillow][:metricsComments] << "PROPERTY NOT FOUND"
      output[:Zillow][:metricsUsage] << "PROPERTY NOT FOUND"
      output[:reason] << "Not Found"

      combineMetricOutputs(output)
      output[:runTime] = 0

      saveOutputRecord(address, output, params)
      return true
    end
    return false
  end

  # Save the output data for a property
  def saveOutputRecord(address, output, params)
    newOutput = Output.new
    newOutput.place_id = output[:placeId]
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
    newOutput.zpid = output[:zpid]
    newOutput.save
  end

  # Determine if the property is approved
  def getDecision(output, data_source)
    key = data_source.to_sym

    # Last sold check
    idx = output[key][:metricsNames].index("Last Sold History")
    output[:reason][0] = "Sold too recently" if !output[key][:metricsPass][idx]

    # Rurality Checks
    rs_idx = output[:Census][:metricsNames].index("Rurality Score")
    vol_idx = output[key][:metricsNames].index("St. Dev. of Historical Home Price")

    if output[:region] == "East"
     output[:reason][1] = "Too rural" if (!output[:Census][:metricsPass][rs_idx] || !output[key][:metricsPass][vol_idx])    
    end

    if output[:region] == "West"
      output[:reason][1] = "Too rural" if !output[:Census][:metricsPass][rs_idx]
    end

    # Typicality
    typ_idx = output[key][:metricsUsage].each_index.select { |i| output[key][:metricsUsage][i] == "Typicality" }
    typ_fail_cnt = typ_idx.inject([]) { |tot, a| tot << output[key][:metricsPass][a] }.count(false)

    if data_source == "Zillow"
      neigh_idx = output[key][:metricsNames].index("Neighbors Available")
      sqft_idx = output[key][:metricsNames].index("SqFt Typicality - Comps")
      est_idx = output[key][:metricsNames].index("Estimate Typicality - Comps")

      if output[key][:metrics][neigh_idx] >= 4
        sqfi_nb_idx = output[key][:metricsNames].index("SqFt Typicality - Neighbors")
        est_nb_idx = output[key][:metricsNames].index("Estimate Typicality - Neighbors")

        output[:reason][2] = "Atypical property" if typ_fail_cnt >= 3
        output[:reason][2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 65.0 || output[key][:metrics][est_idx] > 65.0)
        output[:reason][2] = "Atypical property" if !output[key][:metricsPass][sqft_idx] && !output[key][:metricsPass][sqfi_nb_idx]
        output[:reason][2] = "Atypical property" if !output[key][:metricsPass][est_idx] && !output[key][:metricsPass][est_nb_idx]
      else
        output[:reason][2] = "Atypical property" if typ_fail_cnt >= 2
        output[:reason][2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 60.0 || output[key][:metrics][est_idx] > 60.0)
      end
    else
      output[:reason][2] = "Atypical property" if typ_fail_cnt >= 2
      output[:reason][2] = "Atypical property" if typ_fail_cnt >= 1 && (output[key][:metrics][sqft_idx] > 60.0 || output[key][:metrics][est_idx] > 60.0)
    end

    # Liquidity (allow one false)
    liq_idx = output[key][:metricsUsage].each_index.select { |i| output[key][:metricsUsage][i] == "Liquidity" }
    liq_fail_cnt = liq_idx.inject([]) { |tot, a| tot << output[key][:metricsPass][a] }.count(false)
    output[:reason][3] = "Illiquidity" if liq_fail_cnt >= 2

    # Investment Guidelines
    est_idx = output[key][:metricsNames].index("Estimated Value")
    type_idx = output[key][:metricsNames].index("Property Use")
    build_idx = output[key][:metricsNames].index("Build Date")
    msa_idx = output[key][:metricsNames].index("Pre-approval")

    output[:reason][4] = "Out of $ Range" if !output[key][:metricsPass][est_idx]
    output[:reason][5] = "Not Prop Type" if !output[key][:metricsPass][type_idx]
    output[:reason][6] = "New Construction" if !output[key][:metricsPass][build_idx]
    output[:reason][7] = "Not in MSAs" if !output[key][:metricsPass][msa_idx]

    # Volatility (allow one false)
    vol_idx = output[key][:metricsUsage].each_index.select { |i| output[key][:metricsUsage][i] == "Volatility" }
    vol_fail_cnt = vol_idx.inject([]) { |tot, a| tot << output[key][:metricsPass][a] }.count(false)
    output[:reason][8] = "Price Vol" if vol_fail_cnt >= 2

    # Combo Rural (if applicable)
    cr_idx = output[:Census][:metricsNames].index("Combo Rural")
    output[:reason][9] = "Combo Rural" if !output[:Census][:metricsPass][cr_idx]

    # Distance
    output[:reason][10] = "MSA Distance" if !output[:Google][:metricsPass].any?

    # Approve if not issues
    output[:reason][11] = "Approved" if output[:reason].compact.size == 0
  end
end