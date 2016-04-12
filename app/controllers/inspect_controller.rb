class InspectController < ApplicationController

  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'

  def inspect
  	outputs = Output.all
    id = params[:id]
    @output = outputs.find_by(id: id)
    @public = !current_user.admin?   
    render 'inspect'
  end

  def inspectaddress
    outputs = Output.all
    street = params[:street]
    citystatezip = params[:citystatezip]
    @public = !current_user.admin?    
    @output = outputs.find_by(street: URI.unescape(street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip), citystatezip: URI.unescape(citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip))
    if @output == nil
      @calcurl = "/getvalues/calc/"+street+"/"+citystatezip
      @street = URI.unescape(street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip)
      @citystatezip = URI.unescape(citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip)
      return render 'waiting'
    end

    render 'inspect'
  end

  def decision
    puts "In the decision controller"
    @waiting = true
    loopcount = 0
    while @waiting == true && loopcount <= 10
      outputs = Output.all
      street = params[:street]
      citystatezip = params[:citystatezip]
      @waiting = false
      @output = outputs.find_by(street: URI.unescape(street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip), citystatezip: URI.unescape(citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip))
      if @output == nil
        @waiting = true
        sleep 1
      end
      loopcount += 1
      puts loopcount
    end
    render 'decision'
  end

  def oneoff
    render 'oneoff'   
  end
  
end
