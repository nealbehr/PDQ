class ResearchController < ApplicationController
  
  # Load in gems
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'
  require 'mixpanel-ruby'
  require 'httparty'

  # Define class variables
  @@rurality_names = ['Urban Density','Census Tract Density','Surrounding Census Tract Density','Census Block Density','Census Block Houses','Rurality Score']
  @@MLS_TOKEN = "b49bd1d9d1932fc26ea257baf9395d26"
  @@MLS_filters = {"mls.name" => "sfar",
                  "primary.mpoStatus" => "active",
                  "primary.price.listingPrice" => "[250000 TO 5000000]", # price condition
                  "mls.knownShortSale" => 'false',
                  "construction.yearBuilt" => "{* TO " + (Time.now.year.to_i-1).to_s + "}", # build year condition
                  "primary.mpoPropType" => "(singleFamily OR condominium OR loft OR apartmentBuilding)"}

  # Pulls data items relevant to rurality
  def ruralityData
  	alldata = Output.find_by(id: params[:id])
    if alldata != nil
      @Output = ResearchFunctions.getRuralityData(alldata, @@rurality_names)
    else
      @Output = {name: "Does not exist"}.to_json
    end
    render :json => @Output
  end

  def mlstest()
    @Output = MlsApi.getIndividualProperty()
    render :json => @Output
  end

  # Returns the output of a PDQ entry in a json form. Used to view historical data
  def getOutputValues
    # Error checking - see if we have a PDQ ID or address item in url
    if params[:id].nil? && (params[:street].nil? && params[:citystatezip].nil?)
      @Output = {:status => "Input Error: ID or address not found"}.to_json
      return render :json => @Output
    end

    # Find the data item in outputs
    if !params[:id].nil?
      data = Output.find_by(id: params[:id])
    elsif !params[:street].nil? && !params[:citystatezip].nil?
      data = Output.find_by(street: params[:street], citystatezip: params[:citystatezip])
    end

    # Parse the data as a json
    jd = JSON.parse(data.to_json)

    # Convert to arrays if necessary (testing vs. production differences)
    jd["names"] = YAML.load(jd["names"]) unless jd["names"].is_a?(Array)
    jd["numbers"] = YAML.load(jd["numbers"]) unless jd["numbers"].is_a?(Array)
    jd["passes"] = YAML.load(jd["passes"]) unless jd["passes"].is_a?(Array)

    # YAML required since the arrays are actually stored as strings
    @Output = {:id => jd["id"],
               :street => jd["street"],
               :citystatezip => jd["citystatezip"],
               :time => jd["time"],
               :zpid => jd["zpid"],
               :date => jd["date"],
               :product => jd["product"],
               :names => jd["names"],
               :numbers => jd["numbers"],
               :passes => jd["passes"]
              }.to_json

    render :json => @Output
  end

  # URL to hit our MSA mapping db
  def getMsa
    census_geo, url = CensusApi.getGeoInfo(params[:lat], params[:lon])
    @Output = MsaMapping.getMsaByGeo(census_geo[:partialGeoId])
    render :json => @Output
  end

  ### MLS Functions - can be transferred to python
  def mlsNewListings
    # Construct filters
    @@MLS_filters["mls.onMarketDate"] = params[:date]

    # Get property based on return size; return all if "all"
    # A value of nil will return 2 results at most
    if params[:size] == "all"
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = 5000)
    else
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = params[:size])
    end

    # Get properties and render as json
    @MLS_data = MlsApi.getPropertiesByQuery(url_call)
    render :json => @MLS_data
  end

  ### MLS Functions - can be transferred to python
  def mlsDaysOnMarket 
    # Construct filters
    today = Time.now.to_date
    thres_date = today - params[:dayCount].to_i
    @@MLS_filters['mls.onMarketDate'] = "[* TO " + thres_date.to_s + "]"

    # Get property based on return size; return all if "all"
    # A value of nil will return 2 results at most
    if params[:size] == "all"
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = 5000)
    else
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = params[:size])
    end

    # Get properties and render as json
    @MLS_data = MlsApi.getPropertiesByQuery(url_call)
    render :json => @MLS_data
  end

  # Under construction
  def mlsDataByGeo
    puts "In geo mls"
    @MLS_loc_data = MlsApi.getMlsPropertiesByGeo(@@MLS_TOKEN, 37.7755128, -122.4180038) # lat/lon for testing
    render :json => @MLS_loc_data
  end

  # Function to be used as a cron job and run multiple new listings from mls for approval
  def mlsAutoPreQual
    # Check max runs
    daily_pdq_cnt = Output.where("runid LIKE ?", "%#{Time.now.to_date}").length
    max_count = 400 - daily_pdq_cnt
    max_count = 2
    puts "max_count: #{max_count}"

    # Build POST call
    base_url = "https://api.mpoapp.com/v1/properties/_search?api_key=#{@@MLS_TOKEN}"
    h = {"Content-Type" => 'application/json; charset=UTF-8', "Cache-Control" => "no-cache"}

    data = {:from => 0, :size => max_count, :sort => {:_created => {:order => "desc"}}}

    query_string = "primary.price.listingPrice: [250000 TO 5000000]" # price condition
    query_string += " AND mls.onMarketDate:[#{(Time.now.to_date - params[:dayCount].to_i).to_s} TO *]" # days on market
    query_string += " AND construction.yearBuilt: {* TO #{(Time.now.year.to_i-1).to_s}}" # build year condition"

    data[:query] = {:bool => {:minimum_should_match => 1, 
                              :must => [
                                          {:query_string => {:query => query_string}},
                                          {:terms => {"primary.mpoPropType" => ["singleFamily", "condominium", "loft", "apartment"]}},
                                          {:terms => {"primary.mpoStatus" => ["active"]}},
                                          {:terms => {"mls.knownShortSale" => ["false"]}},
                                          
                                        ]
                              }
                  }

    # PDQ params
    pdq_params = {:path => "Mls"}
    runID = "#{pdq_params[:path]}: #{Date.today.to_s}"

    # Get Results
    response = HTTParty.post(base_url, :body => data.to_json, :headers => h)
    json_result = JSON.parse(response.to_json)    
    results = json_result["results"]

    # Get Addresses
    results.each do |r|
      values =  r["primary"]["address"]

      # Build street
      street = values["streetNum"]
      street += " #{values["streetDirection"]}" unless values["streetDirection"].nil?
      street += " #{values["streetName"]}" unless values["streetName"].nil?
      street += " #{values["streetSuffix"]}" unless values["streetSuffix"].nil?
      street += " Unit #{values["unitNum"]}" unless values["unitNum"].nil?

      # Build city, state, zip
      csz = "#{values["city"]}, #{values["state"]} #{values["zipCode"]}"

      # Run through PDQ
      # street = MiscFunctions.addressStringClean(street)
      # csz = MiscFunctions.addressStringClean(csz)
      print "#{street} + #{csz}"
      geo_data = GeoFunctions.getGoogleGeoByAddress(street, csz)

      a = PdqEngine.computeDecision(geo_data, pdq_params, runID)
    end

    @outputs = Output.all
    @forexport = false
    render 'outputs/index'
  end

end
