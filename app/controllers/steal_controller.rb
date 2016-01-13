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
    endpoint = 1
    @startNeighbors = 0
    @startCensustracts = 0    
    @comment = "Change [overwrite] [test] [all] params for additional functionality. Check coder comments for details."

    ###################################################################################
    #                                                                                 #
    #   Call this url if brave:      steal?delete=on&safety=off&key=protecteddatabase #
    #   Call this url to load data:  steal?all=on&safety=off                          #
    #   Call this url to test:       steal?test=on                                    #
    #                                                                                 #
    ###################################################################################

    if params[:all] == "on" && params[:safety] == "off"
      puts "Thumbs up, let's do this. LEEROY JENKINS!"
      @comment = "Databases created"
      endpoint = 505676
    end

    if params[:test] == "on"
      @comment = "Test completed"
      puts "Test away!"      
      endpoint = 431580
    end

    if params[:delete] == "on" && params[:safety] == "off" && params[:key] == "protecteddatabase"
      Neighbor.find_in_batches(:batch_size => 100) do |textos|
        puts "Neighbor batch complete: " + textos[0].home.to_s
        textos.each{| texto | 
          texto.destroy
        }
      end
      Censustract.find_in_batches(:batch_size => 100) do |textos|
        puts "Censustract batch complete: " + textos[0].home.to_s
        textos.each{| texto | 
          texto.destroy
        }
      end
      @comment = "Everything deleted"      
    end


    for q in 431574..endpoint
      puts q      
      url = "http://www.usboundary.com/Tools/Neighbors/"+q.to_s+"/GetNeighborsHtml?options=%7B%22uaid%22%3A"+q.to_s+"%2C%22neighborAreaTypeID%22%3A28%2C%22neighborTypes%22%3A%7B%22Touches%22%3Atrue%2C%22Contains%22%3Afalse%2C%22Contained%22%3Afalse%2C%22Overlaps%22%3Afalse%7D%2C%22numPerPage%22%3A120%2C%22displayPages%22%3A7%2C%22page%22%3A1%2C%22pageURLPrefix%22%3A%22javascript%3AloadNeighborsTable%22%2C%22highlightedUAID%22%3A-1%7D"
      @page = Nokogiri::HTML(open(url))
      @table = Array.new
      @table = @page.to_s.split("col_name_")
      loopreturner = ""
      for x in 1..@table.size-1
        loopreturner = loopreturner.to_s + "||" + @table[x][0..5].to_s
      end
      @newNeighbor = Neighbor.new      
      @newNeighbor.home = q
      @newNeighbor.neighbor = loopreturner[2..100000000]
      @newNeighbor.save
      @startNeighbors += 1


      url = "http://www.usboundary.com/api/areadata/geom/?id="+q.to_s+"&zoom=4"
      @page = Nokogiri::HTML(open(url))

      @textoutput = @page.to_s.split("\"UAID\"")
      @textoutput = @textoutput[1].to_s.split(",\"")
      for x in 0..@textoutput.size-1
        @textoutput[x] = @textoutput[x].gsub("\"","").gsub(":","")
      end

      if @textoutput != nil && @textoutput[5] != nil
      # begin
        @newCensustract = Censustract.new      
        @newCensustract.home = q.to_f
        @newCensustract.name = @textoutput[5][4..10000].to_f
        @newCensustract.area = (@textoutput[9][5..10000].to_f/2589990.0).to_f
        @newCensustract.pop = @textoutput[13][3..10000].to_f
        @newCensustract.hu = @textoutput[14][2..10000].to_f
        @newCensustract.state = @textoutput[1][7..10000].to_f
        @newCensustract.county = @textoutput[2][8..10000].to_f
        @newCensustract.tractid = @textoutput[3][7..10000].to_s
        @newCensustract.geoid = @textoutput[4][5..10000].to_s
        @newCensustract.lat = @textoutput[11][8..10000].to_f
        @newCensustract.lon = @textoutput[12][8..10000].to_f
        @newCensustract.stringname = @textoutput[6][8..10000].to_s
        @newCensustract.save
        @startCensustracts += 1
      # rescue
      # end
      end
    end
  end

  def showcensustract
    if params[:home] == nil && params[:name] == nil
      @censustracts = Censustract.all
    elsif params[:home] != nil
      @censustracts = Censustract.where(home: params[:home])      
    else
      @censustracts = Censustract.where(name: params[:name])      
    end
  end

  def showneighbor
    if params[:home] == nil && params[:name] == nil
      @neighbors = Neighbor.all
    elsif params[:home] != nil
      @neighbors = Neighbor.where(home: params[:home])      
    else
      @neighbors = Neighbor.where(name: params[:name])      
    end
  end

  def scrape
      @page = Nokogiri::HTML(open("http://www.zillow.com/homes/"+params[:zpid].to_s))
      puts scrappingtable = @page.css('div#yui_3_18_1_2_1450749722036_586')
  end

end



# Need to figure out how to return an array...

# <%= Neighbor.where(home: 12345).first.neighbor %>, 

# <br>
# <br>
# <% relevanttract = Censustract.find_by(home: 12345) %>


# Density: <%= relevanttract.hu.to_f / relevanttract.area.to_f  %>, 
# <br>

