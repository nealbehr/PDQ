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
    render 'inspect'
  end

  def inspectaddress
    outputs = Output.all
    street = params[:street]
    citystatezip = params[:citystatezip]
    @public = true
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
    outputs = Output.all
    street = params[:street]
    citystatezip = params[:citystatezip]
    @waiting = false
    @output = outputs.find_by(street: URI.unescape(street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip), citystatezip: URI.unescape(citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip))
    if @output == nil
      @waiting = true
    end
    render 'decision'
  end

end
