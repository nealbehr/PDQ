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
                  "primary.mpoPropType" => "(singleFamily OR condominium OR Loft OR Apartment Building)"}
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
      puts data
    end

    # Parse the data as a json
    jd = JSON.parse(data.to_json)

    # YAML required since the arrays are actually stored as strings
    @Output = {:id => jd["id"],
               :street => jd["street"],
               :citystatezip => jd["citystatezip"],
               :time => jd["time"],
               :zpid => jd["zpid"],
               :date => jd["date"],
               :product => jd["product"],
               :names => YAML.load(jd["names"]),
               :numbers => YAML.load(jd["numbers"]),
               :passes => YAML.load(jd["passes"])
              }.to_json

    render :json => @Output
  end

  ### MLS Functions
  def mlsNewListings
    # Construct filters
    @@MLS_filters["mls.onMarketDate"] = params[:date]

    # Get property based on return size; return all if "all"
    # A value of nil will return 2 results at most
    if params[:size] == "all"
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = 500)
    else
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = params[:size])
    end

    # Get properties and render as json
    @MLS_data = MlsApi.getPropertiesByQuery(url_call)
    render :json => @MLS_data
  end

  def mlsDaysOnMarket
    # Construct filters
    today = Time.now.to_date
    thres_date = today - params[:dayCount].to_i
    @@MLS_filters['mls.onMarketDate'] = "[* TO " + thres_date.to_s + "]"

    # Get property based on return size; return all if "all"
    # A value of nil will return 2 results at most
    if params[:size] == "all"
      url_call = MlsApi.createMlsUrl(@@MLS_TOKEN, @@MLS_filters, query_size = 500)
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
end
