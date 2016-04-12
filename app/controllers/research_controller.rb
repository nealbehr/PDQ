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

  include ResearchFunctions

  # Define Class Variables
  @@rurality_names = ['Urban Density','Census Tract Density','Surrounding Census Tract Density','Census Block Density','Census Block Houses','Rurality Score']
  @@MLS_TOKEN = "b49bd1d9d1932fc26ea257baf9395d26"

  
  def ruralitydata
  	alldata = Output.find_by(id: params[:id])
  	@Output = getRuralityData(alldata, @@rurality_names)
    @forexport = true
  	#render 'ruralitydata'
    render :json => @Output
  end

  def mlsdatatest
    puts "In mlsdatatest"
    @MLS_data = getMlsProperties(@@MLS_TOKEN, params[:size])
    @forexport = true
    render :json => @MLS_data
  end

  def mlsDataByGeo
    puts "In geo mls"
    @MLS_loc_data = test_httparty(@@MLS_TOKEN)
    @forexport = true
    render :json => @MLS_loc_data
  end
end
