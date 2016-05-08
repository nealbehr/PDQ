class ValuesController < ApplicationController
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

  ############################################################
  #  Coder Notes: always read before committing and pushing  #
  ############################################################
  #<^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^>#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<                                                        >#
  #<vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv>#
  ############################################################
  #||||||||||||||||||||||||||||||||||||||||||||||||||||||||||#
  ############################################################

  # def getvalues
  #   # Call the original version of get values
  #   @addresses = GetValuesArchive.getValues(params)

  #   @allOutput = Output.all
  #   if params[:path] == nil
  #     return render 'getvalues'
  #   end

  #   @calcedurl = "/inspect/"+params[:street]+"/"+params[:citystatezip]
  #   return render 'blank'
  # end

  # under construction
  def getvalues
    # Track via mixpanel
    MiscFunctions.mixPanelTrack(params[:street], params[:citystatezip], params[:product])

    # Determine if this is a bulk run or single property
    if params[:street].nil? || params[:citystatezip].nil?
      @addresses = Address.all
      runID = "Run: " + addresses.size.to_s + ": "+ Date.today.to_s
      
    else # if single property, create new address record
      a = Address.new
      a.street = MiscFunctions.addressStringClean(params[:street])
      a.citystatezip = MiscFunctions.addressStringClean(params[:citystatezip])

      # Save new address in a one element array
      @addresses = [a]
      puts @addresses
      
      runID = params[:path].to_s.capitalize + ": " + Date.today.to_s
    end

    # Loop over records and compute PDQ score
    @addresses.each { |prop| PdqEngine.computeDecision(prop, params, runID) }

    # Aggregate all output and render
    @allOutput = Output.all
    return render 'getvalues' if params[:path].nil?

    @calcedurl = "/inspect/" + params[:street] + "/" + params[:citystatezip]
    return render 'blank'
  end

end