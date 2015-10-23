class StealController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require 'rubygems'
  require 'open-uri'
  require 'json'
  require 'openssl'
  require 'date'
  require 'time'
  def steal
    startNeighbors = 0
    @outputNeighbors  = Array.new
    startDensity = 0    
    @outputDensity  = Array.new
    # for q in 431574..505676

    for q in 431574..505676
      url = "http://www.usboundary.com/Tools/Neighbors/"+q.to_s+"/GetNeighborsHtml?options=%7B%22uaid%22%3A"+q.to_s+"%2C%22neighborAreaTypeID%22%3A28%2C%22neighborTypes%22%3A%7B%22Touches%22%3Atrue%2C%22Contains%22%3Afalse%2C%22Contained%22%3Afalse%2C%22Overlaps%22%3Afalse%7D%2C%22numPerPage%22%3A120%2C%22displayPages%22%3A7%2C%22page%22%3A1%2C%22pageURLPrefix%22%3A%22javascript%3AloadNeighborsTable%22%2C%22highlightedUAID%22%3A-1%7D"
      puts q
      @page = Nokogiri::HTML(open(url))
      @table = Array.new
      @table = @page.to_s.split("col_name_")
      for x in 1..@table.size-1
        @outputNeighbors[startNeighbors] = {home: q, neighbor: @table[x][0..5].to_i}
        startNeighbors += 1
      end
      url = "http://www.usboundary.com/api/areadata/geom/?id="+q.to_s+"&zoom=4"
      @page = Nokogiri::HTML(open(url))

      @textoutput = @page.to_s.split("\"UAID\"")
      @textoutput = @textoutput[1].to_s.split(",\"")
      for x in 0..@textoutput.size-1
        @textoutput[x] = @textoutput[x].gsub("\"","").gsub(":","")
      end
      begin
        @outputDensity[startDensity] = {home: q, name: @textoutput[5][4..10000].to_f, area: @textoutput[9][5..10000].to_f/2590000.0, pop: @textoutput[13][3..10000].to_f, hu: @textoutput[14][2..10000].to_f}
        startDensity += 1
      rescue
      end
    end
  end
end


