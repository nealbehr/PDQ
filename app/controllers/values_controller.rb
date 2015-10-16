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

  def getvalues
    if params[:street] == nil || params[:citystatezip]== nil
      @addresses = Address.all
      runID = "Run: " + @addresses.size.to_s + ": "+ Date::today.to_s
    else
      @addresses = Array.new
      @address = Address.new
      @address.street = URI.unescape(params[:street].to_s.upcase.gsub(",","").gsub("+"," ").strip)
      @address.citystatezip = URI.unescape(params[:citystatezip].to_s.upcase.gsub(",","").gsub("+"," ").strip)
      @addresses[0] = @address
      runID = params[:path].to_s.capitalize + ": " +Date::today.to_s
    end
    @allOutput = Output.all
    distanceThreshold = 1000

    @startTime = Time.now
    @sectionTimes = Array.new
    @sectionTimes.push(Time.now-@startTime)    

    for q in 0..@addresses.size-1

      metrics = Array.new
      metricsNames = Array.new
      metricsPass = Array.new
      metricsComments = Array.new
      metricsUsage = Array.new
      metricsCount = 0
      urlsToHit = Array.new
      reason = Array.new
      @output = Output.find_by(street: URI.unescape(@addresses[q].street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip), citystatezip: URI.unescape(@addresses[q].citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip))
      if @output != nil
        @sectionTimes.push((Time.now-@startTime-@sectionTimes.inject(:+)).round)
        next
      end

      url = URI.parse('http://www.zillow.com/webservice/GetDeepSearchResults.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&address='+URI.escape(@addresses[q].street)+'&citystatezip='+URI.escape(@addresses[q].citystatezip))
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      @evalProp = Nokogiri::XML(res.body)
      urlsToHit.push(url.to_s.gsub(",","THESENTINEL"))

      puts @evalProp.at_xpath('//zpid')
      puts @evalProp.at_xpath('//results//result//address')

      if @evalProp.at_xpath('//zpid') == nil || @evalProp.at_xpath('//results//result//zestimate//amount') == nil

        metricsNames[metricsCount] = "ZILLOW API FAIL"
        metrics[metricsCount]= "PROPERTY NOT FOUND"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "PROPERTY NOT FOUND"
        metricsUsage[metricsCount] = "PROPERTY NOT FOUND"
        reason.push("Not Found")
        
        @newOutput = Output.new      
        @newOutput.street = @addresses[q].street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip
        @newOutput.citystatezip = @addresses[q].citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip
        @newOutput.names = metricsNames
        @newOutput.numbers = metrics
        @newOutput.passes = metricsPass
        @newOutput.urls = urlsToHit
        @newOutput.reason = reason
        @newOutput.comments = metricsComments
        @newOutput.usage = metricsUsage
        @newOutput.zpid = @zpid.to_s
        @newOutput.runid = runID
        @newOutput.time = (Time.now-@startTime-@sectionTimes.inject(:+)).round
        @newOutput.save

        @sectionTimes.push((Time.now-@startTime-@sectionTimes.inject(:+)).round)
        next
      end
      @zpid = @evalProp.at_xpath('//zpid').content

      url = URI.parse('http://www.zillow.com/webservice/GetDeepComps.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&zpid='+@zpid+'&count=25')
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      @compOutput = Nokogiri::XML(res.body)
      urlsToHit.push(url.to_s)

      url = URI.parse('http://www.zillow.com/webservice/GetDemographics.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&state='+@evalProp.at_xpath('//result//address').at_xpath('//state').content+'&city='+URI.escape(@evalProp.at_xpath('//result//address').at_xpath('//city').content)+"&zipcode="+@evalProp.at_xpath('//result//address').at_xpath('//zipcode').content)
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      @evalNeighborhood = Nokogiri::XML(res.body)
      urlsToHit.push(url.to_s)




      
      metricsNames[metricsCount] = "Zestimate"
      metrics[metricsCount]=@evalProp.at_xpath('//results//result//zestimate//amount').content
      metricsPass[metricsCount] = metrics[0].to_i < 5000000 && metrics[0].to_i > 300000
      metricsComments[metricsCount]= "< 5000000 & > 300000"
      metricsUsage[metricsCount] = "Price Range"


      
      metricsCount += 1
      metricsNames[metricsCount] = "Pre-approval"
      metricsUsage[metricsCount] = "MSA check"


      metrics[metricsCount]= getaPrequal(@evalProp.at_xpath('//results//address//zipcode').content.to_i)
      metricsPass[metricsCount] = metrics[metricsCount] == -1 ? false : true
      if metrics[metricsCount] == -1
        metricsComments[metricsCount] = "Not found in database"
      elsif metrics[metricsCount] == 1 
        metricsComments[metricsCount] = "Found in database. Mapped to true"
      elsif metrics[metricsCount] == 0
        metricsComments[metricsCount] = "Found in database. Mapped to false"
      else        
        metricsComments[metricsCount] = "There was an error evaluating prequal"
      end


      if @evalProp.at_xpath("//response//results//result//lastSoldDate") == nil

        metricsCount += 1
        metricsNames[metricsCount] = "Last sold history"
        metrics[metricsCount]= "Not available"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Recent Sale"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Last sold history"
        metrics[metricsCount]= Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y").to_s.sub(",", "")
        metricsPass[metricsCount] = Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y") < Date.today - 365
        metricsComments[metricsCount]= "Time from today: " + ((Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y") - Date.today).to_i * -1).to_s + " days"
        metricsUsage[metricsCount] = "Recent Sale"
      end
      if @compOutput.xpath("//response//properties//comparables//comp")!= nil
        @comparables = @compOutput.xpath("//response//properties//comparables//comp")
        total = 0
        for x in 0..@comparables.size-1
          total += @comparables[x].attribute('score').value.to_f
        end

        
        metricsCount += 1
        metricsNames[metricsCount] = "Zillow Comparable score"
        metrics[metricsCount]= (total/@comparables.size.to_f).round(2)
        metricsPass[metricsCount] = total/@comparables.size.to_f > 6.0
        metricsComments[metricsCount]= " > 6.0"
        metricsUsage[metricsCount] = "Liquidity"

        
        metricsCount += 1
        metricsNames[metricsCount] = "Zillow Comparable count"
        metrics[metricsCount]= @comparables.size.to_i
        metricsPass[metricsCount] = @comparables.size.to_i > 4
        metricsComments[metricsCount]= "> 4"
        metricsUsage[metricsCount] = "Liquidity"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Zillow Comparable score"
        metrics[metricsCount]= "Comps not found"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Liquidity"

        
        metricsCount += 1
        metricsNames[metricsCount] = "Zillow Comparable count"
        metrics[metricsCount]= "Comps not found"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Liquidity"
      end
      @page = Nokogiri::HTML(open("http://www.zillow.com/homes/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content+"_zpid/"))
      scrappingtable = @page.css('div#hdp-unit-list').css('td')

      urlsToHit.push("http://www.zillow.com/homes/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content+"_zpid/")
      @distance = Array.new
      totalPrice = 0
      totalBeds = 0
      totalBaths = 0
      totalSqFt = 0
      totalRecords = 0
      totalDistance = 0
      totalDistanceCount = 0
      totalDistanceSansOutliers = 0
      totalDistanceCountSansOutliers = 0
      for x in 0..scrappingtable.size/5-1
        skipflag = false
        url = URI.parse("http://nominatim.openstreetmap.org/search/"+URI.escape(scrappingtable[5*x+0].content) +"?format=json&addressdetails=1")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        urlsToHit[4+x] = "Success: " + url.to_s.gsub(",","THESENTINEL")
        textOutput = res.body
        if !textOutput.include? "house"
          url = "https://maps.googleapis.com/maps/api/geocode/xml?address=" + URI.escape(scrappingtable[5*x+0].content)+ "&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
          geocoderOutput = Nokogiri::XML(open(url))
          if geocoderOutput.at_xpath('//location_type') == nil
            skipflag = true
            urlsToHit[4+x] = "GoogleFail: " + url.to_s.gsub(",","THESENTINEL")
          elsif geocoderOutput.at_xpath('//location_type').content.include? "ROOFTOP"
            lat2 = geocoderOutput.at_xpath('//location//lat').content
            lon2 = geocoderOutput.at_xpath('//location//lng').content
            urlsToHit[4+x] = "Google: " + url.to_s.gsub(",","THESENTINEL")            
          else
            skipflag = true
            urlsToHit[4+x] = "GoogleFail: " + url.to_s.gsub(",","THESENTINEL")   
          end
        else
          jsonOutput = JSON.parse(textOutput)
          lat2 = jsonOutput[0]["lat"].to_f
          lon2 = jsonOutput[0]["lon"].to_f
        end
        
        if skipflag == false
          lat1 = @evalProp.at_xpath('//results//latitude').content
          lon1 = @evalProp.at_xpath('//results//longitude').content
          radiusofearth = 3959 * 5280
          dLat = (lat2.to_f - lat1.to_f) * Math::PI / 180.0
          dLon = (lon2.to_f - lon1.to_f) * Math::PI / 180.0
          a = Math.sin(dLat.to_f/2.0) * Math.sin(dLat.to_f/2) + Math.cos(lat1.to_f * Math::PI / 180.0) * Math.cos(lat2.to_f * Math::PI / 180.0) * Math.sin(dLon.to_f/2.0) * Math.sin(dLon.to_f/2.0)
          c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
          d = radiusofearth * c
          if d > distanceThreshold && urlsToHit[4+x][0..3] != "Goog"
            url = "https://maps.googleapis.com/maps/api/geocode/xml?address=" + URI.escape(scrappingtable[5*x+0].content)+ "&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
            urlsToHit[4+x] = "Recheck: " + url.to_s.gsub(",","THESENTINEL")
            geocoderOutput = Nokogiri::XML(open(url))
            if geocoderOutput.at_xpath('//location_type') == nil
              urlsToHit[urlsToHit.size] = "GoogleFail: " + url.to_s.gsub(",","THESENTINEL")
              next
            elsif geocoderOutput.at_xpath('//location_type').content.include? "ROOFTOP"
              lat2 = geocoderOutput.at_xpath('//location//lat').content
              lon2 = geocoderOutput.at_xpath('//location//lng').content
              radiusofearth = 3959 * 5280
              dLat = (lat2.to_f - lat1.to_f) * Math::PI / 180.0
              dLon = (lon2.to_f - lon1.to_f) * Math::PI / 180.0
              a = Math.sin(dLat.to_f/2.0) * Math.sin(dLat.to_f/2) + Math.cos(lat1.to_f * Math::PI / 180.0) * Math.cos(lat2.to_f * Math::PI / 180.0) * Math.sin(dLon.to_f/2.0) * Math.sin(dLon.to_f/2.0)
              c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
              d = radiusofearth * c
            else
              urlsToHit[4+x] = "GoogleFail: " + url.to_s.gsub(",","THESENTINEL")      
              next
            end
          end
          @distance[x] = d
          if d < 2500
            totalDistanceSansOutliers += d          
            totalDistanceCountSansOutliers += 1
          end
          totalDistance += d
          totalDistanceCount += 1

        end


        if scrappingtable[5*x+2].content == "--" || scrappingtable[5*x+3].content == "--" || scrappingtable[5*x+4].content == "--" || scrappingtable[5*x+1].content == "--"
          next
        end
        if scrappingtable[5*x+1].content.to_s.rindex(".") == nil
          totalPrice += scrappingtable[5*x+1].content.to_s.sub("$","").sub("M","000000").sub("K","000").to_f
        else
          totalPrice += scrappingtable[5*x+1].content.to_s.sub("$","").sub("M","000000").sub("K","000").sub(".","").to_f / (10 ** (scrappingtable[5*x+1].content.to_s.reverse.rindex(".")-1))
        end
        totalBeds += scrappingtable[5*x+2].content.to_f
        totalBaths += scrappingtable[5*x+3].content.to_f
        totalSqFt += scrappingtable[5*x+4].content.to_s.sub(",","").to_f
        totalRecords += 1    
      end

      urlsToHit.push(@distance.to_s.gsub(",","THESENTINEL"))
      urlsToHit.push(totalDistanceSansOutliers.to_s.gsub(",","THESENTINEL"))
      urlsToHit.push(totalDistanceCountSansOutliers.to_s.gsub(",","THESENTINEL"))
      
      if @evalProp.at_xpath('//response//result//bedrooms') != nil

        metricsCount += 1
        metricsNames[metricsCount] = "Average beds in community"
        metrics[metricsCount]= ((@evalProp.at_xpath('//response//result//bedrooms').content.to_f / (totalBeds.to_f/totalRecords.to_f)-1).to_f.round(3)*100).round(1)
        metricsPass[metricsCount] = metrics[metricsCount] < 66 && metrics[metricsCount] > -66
        metricsComments[metricsCount] = "% deviation from community within 66%   || Prop: " + @evalProp.at_xpath('//response//result//bedrooms').content.to_s + "  || Avg: " + (totalBeds.to_f/totalRecords.to_f).to_s
        metricsUsage[metricsCount] = "Typicality"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Average beds in community"
        metrics[metricsCount] = "Not available"
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Typicality"
      end
      if @evalProp.at_xpath('//response//result//bathrooms')!= nil

        metricsCount += 1
        metricsNames[metricsCount] = "Average baths in community"
        metrics[metricsCount]= ((@evalProp.at_xpath('//response//result//bathrooms').content.to_f / (totalBaths.to_f/totalRecords.to_f)-1).to_f.round(3)*100).round(1)
        metricsPass[metricsCount] = metrics[metricsCount] < 66 && metrics[metricsCount] > -66
        metricsComments[metricsCount]=  "% deviation from community within 66%   || Prop: " + @evalProp.at_xpath('//response//result//bathrooms').content.to_s + "  || Avg: " + (totalBaths.to_f/totalRecords.to_f).to_s
        metricsUsage[metricsCount] = "Typicality"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Average baths in community"
        metrics[metricsCount] = "Not available"
        metricsPass[metricsCount] = metrics[metricsCount-1]=="Not available" ? false : true
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Typicality"
      end

      if @evalProp.at_xpath('//response//result//finishedSqFt') != nil

        metricsCount += 1
        metricsNames[metricsCount] = "Average SqFt in community"
        metrics[metricsCount]= (((@evalProp.at_xpath('//response//result//finishedSqFt').content.to_f / (totalSqFt.to_f/totalRecords.to_f)-1)*100).to_f.round(1))
        metricsPass[metricsCount] = metrics[metricsCount] < 40 && metrics[metricsCount] > -40
        metricsComments[metricsCount]= "% deviation from community within 40%   || Prop: " + @evalProp.at_xpath('//response//result//finishedSqFt').content.to_s + "  || Avg: " + (totalSqFt.to_f/totalRecords.to_f).to_s
        metricsUsage[metricsCount] = "Typicality"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Average SqFt in community"
        metrics[metricsCount] = "Not available"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Typicality"
      end

      
      metricsCount += 1
      metricsNames[metricsCount] = "Average Price in community"
      metrics[metricsCount]= (((@evalProp.at_xpath('//response//result//zestimate//amount').content.to_f / (totalPrice.to_f/totalRecords.to_f)-1)*100).to_f.round(1))     
      metricsPass[metricsCount] = metrics[metricsCount] < 40 && metrics[metricsCount]  > -40
      metricsComments[metricsCount]= "% deviation from community within 40%   || Prop: " + @evalProp.at_xpath('//response//result//zestimate//amount').content.to_s + "  || Avg: " + (totalPrice.to_f/totalRecords.to_f).to_s
      metricsUsage[metricsCount] = "Typicality"

      if @evalProp.at_xpath('//useCode') == nil

        metricsCount += 1
        metricsNames[metricsCount] = "Property use"
        metrics[metricsCount]= "Not available"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Typicality"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Property use"
        metrics[metricsCount]= @evalProp.at_xpath('//useCode').content
        metricsPass[metricsCount] = metrics[metricsCount]=="SingleFamily"
        metricsComments[metricsCount]= "Has to be Single family"
        metricsUsage[metricsCount] = "Property Type"
      end

      if @evalProp.at_xpath('//yearBuilt') == nil

        metricsCount += 1
        metricsNames[metricsCount] = "Build Date (No new)"
        metrics[metricsCount]= "Not available"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "New Construction"
      else

        metricsCount += 1
        metricsNames[metricsCount] = "Build Date (No new)"
        metrics[metricsCount]= @evalProp.at_xpath('//yearBuilt').content
        metricsPass[metricsCount] = metrics[metricsCount].to_i < Time.now.year
        metricsComments[metricsCount]= "Can't be built this year"
        metricsUsage[metricsCount] = "Construction"
      end


      metricsCount += 1
      metricsNames[metricsCount] = "Distance to Neighbors"
      metrics[metricsCount]= (totalDistance.to_f/totalDistanceCount.to_f).to_f.round(2)
      metricsPass[metricsCount] = totalDistance.to_f/totalDistanceCount.to_f < 700
      metricsComments[metricsCount]= "< 700"
      metricsUsage[metricsCount] = "Rurality"

      
      metricsCount += 1
      metricsNames[metricsCount] = "Number of Neighbors"
      metrics[metricsCount]= totalDistanceCount.to_i
      metricsPass[metricsCount] = totalDistanceCount.to_f>15
      metricsComments[metricsCount]= "> 15"
      metricsUsage[metricsCount] = "Rurality"

      
      metricsCount += 1
      metricsNames[metricsCount] = "Furthest Neighbor"
      metrics[metricsCount]= @distance.map(&:to_f).max.to_f.round(2)
      metricsPass[metricsCount] = metrics[metricsCount].to_f < distanceThreshold
      metricsComments[metricsCount]= "< " + distanceThreshold.to_s
      metricsUsage[metricsCount] = "Rurality"


      metricsCount += 1
      metricsNames[metricsCount] = "Urban Density"
      metrics[metricsCount]= getaZCTADensity(@evalProp.at_xpath('//results//address//zipcode').content.to_i).to_f.round(2)
      metricsPass[metricsCount] = metrics[metricsCount].to_f > 500
      metricsComments[metricsCount]= "> 500 people/SqMi"
      metricsUsage[metricsCount] = "Rurality"

      puts "% Done: " + (q.to_f/(@addresses.size-1).to_f).to_s

      begin
        #  metricsCount is incremented before potential errors in the rescue catch. Therefore it is not incremented in the rescue or metrics save stage.
        metricsCount += 1

        loopCounter = 0
        loop do
          url = URI.parse("http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x="+@evalProp.at_xpath('//result//address//longitude').content+"&y="+@evalProp.at_xpath('//result//address//latitude').content+"&benchmark=4&vintage=4&format=json")
          req = Net::HTTP::Get.new(url)
          res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
          }
          @jsonOutputArea = JSON.parse(res.body)
          urlsToHit[urlsToHit.size] = url.to_s + " || "+ (@jsonOutputArea["result"]["geographies"]["Census Tracts"] == nil ? "Fail" : @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"])

          puts "Loop Counter: " + loopCounter.to_s
          puts url if loopCounter>25
          puts @jsonOutputArea if loopCounter>25
          break if loopCounter>25 || @jsonOutputArea["result"]["geographies"]["Census Tracts"] != nil
          loopCounter += 1
        end

        url = URI.parse("http://api.census.gov/data/2010/sf1?get=H0030001&for=tract:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["STATE"]+"+county:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["COUNTY"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        jsonOutputHouseholds = JSON.parse(res.body)
        urlsToHit[urlsToHit.size] = url.to_s


        metricsNames[metricsCount] = "Census Tract Density"
        metrics[metricsCount]= (jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)).to_f.round(2)
        metricsPass[metricsCount] = jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)>500
        metricsComments[metricsCount]= "> 500 Houses/SqMi for tract: " + @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"].to_s
        metricsUsage[metricsCount] = "Rurality"
      rescue
        metricsNames[metricsCount] = "Census Tract Density"
        metrics[metricsCount]= "Error!"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "Error with the Census/Geocoding APIs"
        metricsUsage[metricsCount] = "Rurality"
      end







      cordAdj = Array.new
      cordAdj.push({xadj: +0.02, yadj: 0})
      cordAdj.push({xadj: -0.02, yadj: 0})
      cordAdj.push({xadj: +0, yadj: +0.02})
      cordAdj.push({xadj: +0, yadj: -0.02})
      cordAdj.push({xadj: +0.02, yadj: +0.02})
      cordAdj.push({xadj: +0.02, yadj: -0.02})
      cordAdj.push({xadj: -0.02, yadj: +0.02})
      cordAdj.push({xadj: -0.02, yadj: -0.02})


      censusTractDensities = Array.new
      startingX = @evalProp.at_xpath('//result//address//longitude').content.to_f
      startingY = @evalProp.at_xpath('//result//address//latitude').content.to_f

      for x in 0..7
        begin
          loopCounter = 0
          loop do
            url = URI.parse("http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x="+(startingX+cordAdj[x][:xadj]).to_s+"&y="+(startingY+cordAdj[x][:yadj]).to_s+"&benchmark=4&vintage=4&format=json")
            req = Net::HTTP::Get.new(url)
            res = Net::HTTP.start(url.host, url.port) {|http|
              http.request(req)
            }

            @jsonOutputArea = JSON.parse(res.body)
            urlsToHit[urlsToHit.size] = url.to_s + " || "+ (@jsonOutputArea["result"]["geographies"]["Census Tracts"] == nil ? "Fail" : @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"])
            puts "Loop Counter: " + loopCounter.to_s

            puts url if loopCounter>25
            puts @jsonOutputArea if loopCounter>25
            break if loopCounter>25 || @jsonOutputArea["result"]["geographies"]["Census Tracts"] != nil
            loopCounter += 1
          end

          url = URI.parse("http://api.census.gov/data/2010/sf1?get=H0030001&for=tract:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["STATE"]+"+county:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["COUNTY"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
          req = Net::HTTP::Get.new(url)
          res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
          }
          jsonOutputHouseholds = JSON.parse(res.body)
          urlsToHit[urlsToHit.size] = url.to_s
          if @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"] == 0
            next
          end
          censusTractDensities.push({censustract: @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"], tractdensity: jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)})
        rescue
          censusTractDensities.push({censustract: 31415, tractdensity: 31415})
        end
      end
      
      metricsCount += 1
      metricsNames[metricsCount] = "Surrounding Census Tract Density"
      metrics[metricsCount]= censusTractDensities.sort_by { |holder| holder[:tractdensity] }[0][:tractdensity].to_f.round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 35.0
      metricsComments[metricsCount]= "> 35 houses/SqMi for tract: "+ censusTractDensities.sort_by { |holder| holder[:tractdensity] }[0][:censustract].to_s + " in " +censusTractDensities.count{|holder| holder[:tractdensity] == censusTractDensities.sort_by { |holder| holder[:tractdensity] }[0][:tractdensity]}.to_s + " of 8 directions. Total of " + (censusTractDensities.uniq.size).to_s + " tested."
      metricsUsage[metricsCount] = "Rurality"


      url = URI.parse("http://www.zillow.com/ajax/homedetail/HomeValueChartData.htm?mt=1&zpid="+URI.escape(@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content)+"&format=json")
      req = Net::HTTP::Get.new("http://www.zillow.com"+url.request_uri)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")
      jsonOutput = JSON.parse(Nokogiri::HTML(open(url)).css('p')[0].content)
      urlsToHit[urlsToHit.size] = [jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min
      @differencesInPrices = Array.new
      @neighborhoodPrices = Array.new
      @homePrices = Array.new
      for time in 0..[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-1
        @differencesInPrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[0]["points"][jsonOutput[0]["points"].size-1-time]["y"]-jsonOutput[1]["points"][jsonOutput[1]["points"].size-1-time]["y"]

        @neighborhoodPrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[1]["points"][jsonOutput[1]["points"].size-1-time]["y"]

        @homePrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[0]["points"][jsonOutput[0]["points"].size-1-time]["y"]
      end
      begin
        changeInHomePrice = {change: jsonOutput[0]["points"].last["y"] - jsonOutput[0]["points"].first["y"], time: jsonOutput[0]["points"].last["x"] - jsonOutput[0]["points"].first["x"], percent: (jsonOutput[0]["points"].last["y"] - jsonOutput[0]["points"].first["y"]).to_f/jsonOutput[0]["points"].last["y"].to_f, yearly: (jsonOutput[0]["points"].last["y"] - jsonOutput[0]["points"].first["y"]).to_f/jsonOutput[0]["points"].last["y"].to_f/(jsonOutput[0]["points"].last["x"] - jsonOutput[0]["points"].first["x"]).to_f*31556926000, recentchange: jsonOutput[0]["points"].last["y"]-jsonOutput[0]["points"][-12]["y"], recentpercent: (jsonOutput[0]["points"].last["y"] - jsonOutput[0]["points"][-12]["y"]).to_f/jsonOutput[0]["points"].last["y"].to_f}
        urlsToHit.push(changeInHomePrice)
        changeInNeighborhoodPrice = {change: jsonOutput[1]["points"].last["y"] - jsonOutput[1]["points"].first["y"], time: jsonOutput[1]["points"].last["x"] - jsonOutput[1]["points"].first["x"], percent: (jsonOutput[1]["points"].last["y"] - jsonOutput[1]["points"].first["y"]).to_f/jsonOutput[1]["points"].last["y"].to_f, yearly: (jsonOutput[1]["points"].last["y"] - jsonOutput[1]["points"].first["y"]).to_f/jsonOutput[1]["points"].last["y"].to_f/(jsonOutput[1]["points"].last["x"] - jsonOutput[1]["points"].first["x"]).to_f*31556926000, recentchange: jsonOutput[1]["points"].last["y"]-jsonOutput[1]["points"][-12]["y"], recentpercent: (jsonOutput[1]["points"].last["y"] - jsonOutput[1]["points"][-12]["y"]).to_f/jsonOutput[1]["points"].last["y"].to_f}
        urlsToHit.push(changeInNeighborhoodPrice)
      rescue
        changeInHomePrice = {change: 0, time: 0, percent: 0, yearly: 0, recentchange: 0, recentpercent: 0}
        urlsToHit.push(changeInHomePrice)
        changeInNeighborhoodPrice = {change: 0, time: 0, percent: 0, yearly: 0, recentchange: 0, recentpercent: 0}
        urlsToHit.push(changeInNeighborhoodPrice)    
      end
      metricsCount += 1
      metricsNames[metricsCount] = "Std. Dev. of price deltas"
      metrics[metricsCount]= (@differencesInPrices.standard_deviation.to_f/metrics[0].to_f).round(3)
      metricsPass[metricsCount] = metrics[metricsCount] < 0.25
      metricsComments[metricsCount]= "< 0.25 || Standard Deviation of price differences from neighborhood as a percentage of overal zestimate"
      metricsUsage[metricsCount] = "Volatility"

      metricsCount += 1
      metricsNames[metricsCount] = "Range of price deltas"
      metrics[metricsCount]= (@differencesInPrices.range.to_f/metrics[0].to_f).round(3)
      metricsPass[metricsCount] = metrics[metricsCount] < 0.80
      metricsComments[metricsCount]= "< 0.80 || Total range of price difference from neighborhood as a percentage of overal zestimate"
      metricsUsage[metricsCount] = "Volatility"

      metricsCount += 1
      metricsNames[metricsCount] = "Std. Dev. of historical home price"
      metrics[metricsCount]= (@homePrices.standard_deviation.to_f/metrics[0].to_f).round(3)
      metricsPass[metricsCount] = metrics[metricsCount] < 0.1
      metricsComments[metricsCount]= "< 0.1 || Standard Deviation of historical home price as a percentage of overal zestimate"
      metricsUsage[metricsCount] = "Volatility"
      
      schoolScores = Array.new
      metricsCount += 1
      metricsNames[metricsCount] = "Schools"
      begin
        schoolScores.push(@page.css("div[class='nearby-schools-rating']")[0].css("span").text.to_s.gsub("(assigned)","").to_i)
      rescue
      end
      begin
        schoolScores.push(@page.css("div[class='nearby-schools-rating']")[1].css("span").text.to_s.gsub("(assigned)","").to_i)
      rescue
      end
      begin
        schoolScores.push(@page.css("div[class='nearby-schools-rating']")[2].css("span").text.to_s.gsub("(assigned)","").to_i)
      rescue
      end 
      if schoolScores.length.to_f >= 1
        metrics[metricsCount]= (schoolScores.inject{|sum,x| sum + x }).to_f/schoolScores.length.to_f
      else
        metrics[metricsCount]=0
      end

      metricsPass[metricsCount] = metrics[metricsCount] >= 3.5
      metricsComments[metricsCount]= ">= 3.5 || Average school rating across " + schoolScores.length.to_s
      metricsUsage[metricsCount] = "Schools"

      metricsCountBeginBlock = metricsCount
      begin
        if @evalProp.at_xpath('//results//address//state').content.to_s == "CA"
          url = URI.parse(URI.encode("https://maps.googleapis.com/maps/api/distancematrix/xml?origins="+@addresses[q].street+" "+@addresses[q].citystatezip+"&destinations=34.05,-118.25|33.948,-117.3961|38.556,-121.4689|32.7150,-117.1625|37.80,-122.27|37.3382,-121.886|34.4258,-119.7142&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"))
          cities = Array.new
          cities = "Los Angeles CA,Riverside CA,Sacramento CA,San Diego CA,San Francisco CA,San Jose CA,Santa Barbara CA".split(",")
          workforces = Array.new
          workforces = "10223746,3226951,1705161,2498726,3582965,1467959,341011".split(",")
        elsif @evalProp.at_xpath('//results//address//state').content.to_s == "OR" || @evalProp.at_xpath('//results//address//state').content.to_s == "WA"
         url = URI.parse(URI.encode("https://maps.googleapis.com/maps/api/distancematrix/xml?origins="+@addresses[q].street+" "+@addresses[q].citystatezip+"&destinations=45.52,-122.6819|47.6097,-122.3331&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"))
         cities = Array.new
         cities = "Portland OR,Seattle WA".split(",")
         workforces = Array.new
         workforces = "1792977,2803623".split(",")
       elsif @evalProp.at_xpath('//results//address//state').content.to_s == "NY" || @evalProp.at_xpath('//results//address//state').content.to_s == "MA" || @evalProp.at_xpath('//results//address//state').content.to_s == "RI" || @evalProp.at_xpath('//results//address//state').content.to_s == "CT" || @evalProp.at_xpath('//results//address//state').content.to_s == "VT" || @evalProp.at_xpath('//results//address//state').content.to_s == "NH" || @evalProp.at_xpath('//results//address//state').content.to_s == "ME"
         url = URI.parse(URI.encode("https://maps.googleapis.com/maps/api/distancematrix/xml?origins="+@addresses[q].street+" "+@addresses[q].citystatezip+"&destinations=42.37,-71.03|40.77,-73.98|41.73,-71.43|42.75,-73.8|42.93,-78.73&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"))
         cities = Array.new
         cities = "Boston MA,New York NY,Providence RI,Albany NY,Buffalo NY".split(",")
         workforces = Array.new
         workforces = "3744480,15787016,1303941,712141,923681".split(",")
       elsif @evalProp.at_xpath('//results//address//state').content.to_s == "NJ" || @evalProp.at_xpath('//results//address//state').content.to_s == "PA" || @evalProp.at_xpath('//results//address//state').content.to_s == "MD" || @evalProp.at_xpath('//results//address//state').content.to_s == "VA" || @evalProp.at_xpath('//results//address//state').content.to_s == "DE" || @evalProp.at_xpath('//results//address//state').content.to_s == "DC"
         url = URI.parse(URI.encode("https://maps.googleapis.com/maps/api/distancematrix/xml?origins="+@addresses[q].street+" "+@addresses[q].citystatezip+"&destinations=39.18,-76.67|39.88,-75.25|40.5,-80.22|36.9,-76.2|38.85,-77.04|40.77,-73.98&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"))
         cities = Array.new
         cities = "Baltimore MD,Philadelphia PA,Pittsburgh PA,Virginia Beach VA,Washington DC,New York NY".split(",")
         workforces = Array.new
         workforces = "2187210,4778663,1949585,1340947,4547518,15787016".split(",")
       else
        puts "We're screwed"
        puts "We're really screwed"
      end
      googleDistancesOutput = Nokogiri::XML(open(url))
      urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")

      ranges = Array.new
      ranges = [
        {city: "Baltimore MD", range: 10000}, 
        {city: "Philadelphia PA", range: 10000}, 
        {city: "Pittsburgh PA", range: 10000}, 
        {city: "Virginia Beach VA", range: 10000}, 
        {city: "Washington DC", range: 100000}, 
        {city: "New York NY", range: 100000}, 
        {city: "Boston MA", range: 10000}, 
        {city: "New York NY", range: 100000}, 
        {city: "Providence RI", range: 10000}, 
        {city: "Albany NY", range: 5000}, 
        {city: "Buffalo NY", range: 5000}, 
        {city: "Los Angeles CA", range: 100000}, 
        {city: "Riverside CA", range: 25000}, 
        {city: "Sacramento CA", range: 34000}, 
        {city: "San Diego CA", range: 75000}, 
        {city: "San Francisco CA", range: 75000}, 
        {city: "San Jose CA", range: 75000}, 
        {city: "Santa Barbara CA", range: 34000}, 
        {city: "Portland OR", range: 22000}, 
        {city: "Seattle WA", range: 61000}
      ]

      metricsCount += 1
      metricsNames[metricsCount] = "Distance from MSA"
      metrics[metricsCount]=googleDistancesOutput.xpath('//element//distance//value').min { |a, b| a.content.to_i <=> b.content.to_i }.content.to_i
      city = cities[googleDistancesOutput.xpath('//element//distance//value').find_index { |qcount| qcount.content.to_i == metrics[metricsCount].to_i } ]
      range = ranges[ranges.index { |x| x[:city] == city}][:range]
      metricsPass[metricsCount] = metrics[metricsCount] <= range
      metricsComments[metricsCount]= "Distance in meters must be less than " + range.to_s + " | Closest MSA: " + city.to_s
      metricsUsage[metricsCount] = "MSA dist"

      metricsCount += 1
      metricsNames[metricsCount] = "Second Distance from MSA"
      metrics[metricsCount]=googleDistancesOutput.xpath('//element//distance//value').sort { |a, b| a.content.to_i <=> b.content.to_i }[1].content.to_i
      city = cities[googleDistancesOutput.xpath('//element//distance//value').find_index { |qcount| qcount.content.to_i == metrics[metricsCount].to_i } ]
      range = ranges[ranges.index { |x| x[:city] == city}][:range]
      metricsPass[metricsCount] = metrics[metricsCount] <= range
      metricsComments[metricsCount]= "Distance in meters must be less than " + range.to_s + " | Closest MSA: " + city.to_s
      metricsUsage[metricsCount] = "MSA Dist"


    rescue Exception => e
      metricsCount = metricsCountBeginBlock
      metricsCount += 1
      metricsNames[metricsCount] = "Distance from MSA"
      metrics[metricsCount]= "NA"
      metricsPass[metricsCount] = false
      metricsComments[metricsCount]= "Distance check failed"
      metricsUsage[metricsCount] = "Rurality"
      metricsCount += 1
      metricsNames[metricsCount] = "Second Distance from MSA"
      metrics[metricsCount]= "NA"
      metricsPass[metricsCount] = false
      metricsComments[metricsCount]= "Distance check failed"
      metricsUsage[metricsCount] = "Rurality"
    end


      metricsCount += 1
      metricsNames[metricsCount] = "Below are non-used variables"
      metrics[metricsCount]= ""
      metricsPass[metricsCount] = ""
      metricsComments[metricsCount]= ""
      metricsUsage[metricsCount] = ""

      metricsCount += 1
      metricsNames[metricsCount] = "Average of historical home price"
      metrics[metricsCount]= @homePrices.average.round
      metricsPass[metricsCount] = metrics[metricsCount]>=0
      metricsComments[metricsCount]= "Mean of price difference from neighborhood"
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Range of historical home price"
      metrics[metricsCount]= (@homePrices.range.to_f/metrics[0].to_f).round(3)
      metricsPass[metricsCount] = metrics[metricsCount] < 0.50
      metricsComments[metricsCount]= "Not tested: Total range of home prices as a percentage of overal zestimate"
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Average of price deltas"
      metrics[metricsCount]= @differencesInPrices.average.round
      metricsPass[metricsCount] = metrics[metricsCount] >= 0
      metricsComments[metricsCount]= "Mean of price difference from neighborhood"
      metricsUsage[metricsCount] = "Not Used"

      urlsToHit.push(@differencesInPrices.to_s.gsub(",","THESENTINEL"))
      urlsToHit.push(@neighborhoodPrices.to_s.gsub(",","THESENTINEL"))        
      urlsToHit.push(@homePrices.to_s.gsub(",","THESENTINEL"))
      urlsToHit.push(censusTractDensities.to_s.gsub(",","THESENTINEL"))


    metricsCountBeginBlock = metricsCount
    begin
      loop do
        url = URI.parse("http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x="+@evalProp.at_xpath('//result//address//longitude').content.to_s+"&y="+@evalProp.at_xpath('//result//address//latitude').content.to_s+"&benchmark=4&vintage=4&format=json")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        @jsonOutputArea = JSON.parse(res.body)
        puts "Loop Counter: " + loopCounter.to_s
        puts url if loopCounter>25
        puts @jsonOutputArea if loopCounter>25
        break if loopCounter>25 || @jsonOutputArea["result"]["geographies"]["Counties"] != nil
        loopCounter += 1
      end


      url = URI.parse("http://api.census.gov/data/2013/acs1/profile?get=DP03_0025E,NAME&for=county:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["COUNTY"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["STATE"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        jsonOutputCommute = JSON.parse(res.body)
        urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")

        metricsCount += 1
        metricsNames[metricsCount] = "County Commute"
        metrics[metricsCount]= jsonOutputCommute[1][0].to_f
        metricsPass[metricsCount] = metrics[metricsCount]<60
        metricsComments[metricsCount]= "< 60 minutes for: " + jsonOutputCommute[1][1].to_s.gsub(",","")
        metricsUsage[metricsCount] = "Not Used"

        url = URI.parse("http://api.census.gov/data/2013/acs1?get=B08012_001E,B08012_011E,B08012_012E,B08012_013E,NAME&for=county:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["COUNTY"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["STATE"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }

        jsonOutputCommute = JSON.parse(res.body)
        urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")      
        metricsCount += 1
        metricsNames[metricsCount] = "Long Commute"
        metrics[metricsCount]= (((jsonOutputCommute[1][1].to_f+jsonOutputCommute[1][2].to_f+jsonOutputCommute[1][3].to_f)/jsonOutputCommute[1][0].to_f)*100).round(1)
        metricsPass[metricsCount] = metrics[metricsCount] < 50
        metricsComments[metricsCount]= "< 50% commute longer than 45 minutes for: " + jsonOutputCommute[1][4].to_s.gsub(",","")
        metricsUsage[metricsCount] = "Not Used"
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        metricsCount = metricsCountBeginBlock + 2
      end


      metricsCountBeginBlock = metricsCount
      begin

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=3500&types=bank&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url.gsub(",","THESENTINEL")
        googlePlacesOutput = Nokogiri::XML(open(url))


        metricsCount += 1
        metricsNames[metricsCount] = "Banks"
        metrics[metricsCount]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[metricsCount] = metrics[metricsCount]>=0
        metricsComments[metricsCount]= "Banks within 3500 meters (~2 miles)"
        metricsUsage[metricsCount] = "Not Used"

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=3500&types=grocery_or_supermarket&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url.gsub(",","THESENTINEL")
        googlePlacesOutput = Nokogiri::XML(open(url))


        metricsCount += 1
        metricsNames[metricsCount] = "Grocery Stores"
        metrics[metricsCount]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[metricsCount] = metrics[metricsCount]>=0
        metricsComments[metricsCount]= "Grocery stores or supermarkets within 3500 meters (~2 miles)"
        metricsUsage[metricsCount] = "Not Used"

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=16000&types=restaurant&minprice=3&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url.gsub(",","THESENTINEL")
        googlePlacesOutput = Nokogiri::XML(open(url))


        metricsCount += 1
        metricsNames[metricsCount] = "Nice restaurants"
        metrics[metricsCount]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[metricsCount] = metrics[metricsCount]>=0
        metricsComments[metricsCount]= "Restaurants with an expense rating of 3+ within 16000 meters (~10 miles)"
        metricsUsage[metricsCount] = "Not Used"


        url = URI.parse("http://api.walkscore.com/score?format=json&lat="+@evalProp.at_xpath('//result//latitude').content+"&lon="+@evalProp.at_xpath('//result//longitude').content+"&wsapikey=8895883fa0b4f996d0344ccee841e098")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        textOutput = res.body
        urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")
        walkScore = JSON.parse(textOutput)


        metricsCount += 1
        metricsNames[metricsCount] = "Walk Score"
        metrics[metricsCount]=walkScore["walkscore"]
        metricsPass[metricsCount] = metrics[metricsCount]>=0
        metricsComments[metricsCount]= "Walkability - Walk Score's measure of neighborhood walkability"
        metricsUsage[metricsCount] = "Not Used"

        url = URI.parse("http://transit.walkscore.com/transit/score/?lat="+@evalProp.at_xpath('//result//latitude').content+"&lon="+@evalProp.at_xpath('//result//longitude').content+"&city=Seattle&state=WA&wsapikey=8895883fa0b4f996d0344ccee841e098")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        textOutput = res.body
        urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")
        transitScore = JSON.parse(textOutput)


        metricsCount += 1
        metricsNames[metricsCount] = "Transit Score"
        metrics[metricsCount]=transitScore["transit_score"]
        metricsPass[metricsCount] = metrics[metricsCount]>=0
        metricsComments[metricsCount]= "Transit Access - Walk Score's measure of neighborhood public transit"
        metricsUsage[metricsCount] = "Not Used"



      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        metricsCount = metricsCountBeginBlock + 5
      end

      begin

        metricsCount += 1
        metricsNames[metricsCount] = "Zestimate confidence"
        metrics[metricsCount]= (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100).round()
        metricsPass[metricsCount] = (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100) < 30
        metricsComments[metricsCount] =  "< 30   ||  " + @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_s + "  -  " + @evalProp.at_xpath('//zestimate//valuationRange//high').content.to_s + "  ||  " + (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100).round().to_s + "%"
        metricsUsage[metricsCount] = "Not Used"
      rescue StandardError=>e

        metricsNames[metricsCount] = "Zestimate Confidence"
        metrics[metricsCount] = "Not available"
        metricsPass[metricsCount] = false
        metricsComments[metricsCount]= "NA"
        metricsUsage[metricsCount] = "Not Used"
      end

      url = URI.parse("http://api.census.gov/data/2013/acs5?get=B10058_001E,B10058_002E,B06011_001E,NAME&for=county:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["COUNTY"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["STATE"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
      req = Net::HTTP::Get.new(url)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      jsonOutputEmployment = JSON.parse(res.body)
      urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")      


      url = URI.parse("http://api.census.gov/data/2010/acs5?get=B10058_001E,B10058_002E,B06011_001E,NAME&for=county:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["COUNTY"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Counties"][0]["STATE"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
      req = Net::HTTP::Get.new(url)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      jsonOutputEmploymentHistorical = JSON.parse(res.body)
      urlsToHit[urlsToHit.size] = url.to_s.gsub(",","THESENTINEL")      



      metricsCount += 1
      metricsNames[metricsCount] = "Labor Force Change"
      metrics[metricsCount]= (((jsonOutputEmployment[1][1].to_f)/jsonOutputEmploymentHistorical[1][1].to_f)*100-100).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 6
      metricsComments[metricsCount]= "> 6% increase in labor force over a three year period: " + jsonOutputEmployment[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Employment Rate"
      metrics[metricsCount]= (((jsonOutputEmployment[1][1].to_f)/jsonOutputEmployment[1][0].to_f)*100).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 50
      metricsComments[metricsCount]= "> 50% Employment rate: " + jsonOutputEmployment[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Employment rate historical"
      metrics[metricsCount]= (((jsonOutputEmploymentHistorical[1][1].to_f)/jsonOutputEmploymentHistorical[1][0].to_f)*100).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 50
      metricsComments[metricsCount]= "> 50% Employment rate: " + jsonOutputEmploymentHistorical[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Employment rate change"
      metrics[metricsCount]= (metrics[metricsNames.index("Employment Rate")] - metrics[metricsNames.index("Employment rate historical")]).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 0
      metricsComments[metricsCount]= "> 0 (increasing) Employment rate: " + jsonOutputEmployment[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Median Income"
      metrics[metricsCount]= (jsonOutputEmployment[1][2].to_f).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 40000
      metricsComments[metricsCount]= "> $40k Median Income: " + jsonOutputEmployment[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Median Income change"
      metrics[metricsCount]= (jsonOutputEmployment[1][2].to_f-jsonOutputEmploymentHistorical[1][2].to_f).round(2)
      metricsPass[metricsCount] = metrics[metricsCount] > 0
      metricsComments[metricsCount]= "> -$0 (increasing) Median income: " + jsonOutputEmployment[1][3].to_s.gsub(",","")
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Future Metrics: Schools"
      metrics[metricsCount]= ""
      metricsPass[metricsCount] = true
      metricsComments[metricsCount]= ""
      metricsUsage[metricsCount] = "Not Used"


      begin
        metricsCount += 1
        url = URI.parse("https://www.quandl.com/api/v1/datasets/ZILL/Z"+@evalProp.at_xpath('//result//address//zipcode').content+"_hf.json?api_key=dzW6tvV6wK_UAW87pXef")
        jsonOutputForeclosure = JSON.parse(url.read)

        if jsonOutputForeclosure["data"] == nil
          puts "Had to nap for a second"
          sleep 1
          url = URI.parse("https://www.quandl.com/api/v1/datasets/ZILL/Z"+@evalProp.at_xpath('//result//address//zipcode').content+"_hf.json?api_key=dzW6tvV6wK_UAW87pXef")
          jsonOutputForeclosure = JSON.parse(url.read)
        end


        urlsToHit.push(url.to_s)


        metricsNames[metricsCount] = "Foreclosures"
        metrics[metricsCount]= (jsonOutputForeclosure["data"][0][1].to_f+jsonOutputForeclosure["data"][1][1].to_f+jsonOutputForeclosure["data"][2][1].to_f)/3.0
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Zillow's estimate of the median market value of homes foreclosed (out of 10k) within the zip code "
        metricsUsage[metricsCount] = "Not Used"
      rescue Exception => e
        metricsNames[metricsCount] = "Ratio: sale price vs. list price"
        metrics[metricsCount]= "N/A"
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "N/A"
        metricsUsage[metricsCount] = "Not Used"

        puts e.message
        puts e.backtrace.inspect
      end

      begin
        metricsCount += 1
        url = URI.parse("https://www.quandl.com/api/v1/datasets/ZILL/Z"+@evalProp.at_xpath('//result//address//zipcode').content+"_slpr.json?api_key=dzW6tvV6wK_UAW87pXef")
        jsonOutputSLPR = JSON.parse(url.read)

        if jsonOutputForeclosure["data"] == nil
          puts "Had to nap for a second"
          sleep 1
          url = URI.parse("https://www.quandl.com/api/v1/datasets/ZILL/Z"+@evalProp.at_xpath('//result//address//zipcode').content+"_slpr.json?api_key=dzW6tvV6wK_UAW87pXef")
          jsonOutputSLPR = JSON.parse(url.read)
        end


        urlsToHit.push(url.to_s)


        metricsNames[metricsCount] = "Ratio: sale price vs. list price"
        metrics[metricsCount]= (jsonOutputSLPR["data"][0][1].to_f+jsonOutputSLPR["data"][1][1].to_f+jsonOutputSLPR["data"][2][1].to_f)/3.0
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Sale price vs list for area"
        metricsUsage[metricsCount] = "Not Used"

      rescue Exception => e

        metricsNames[metricsCount] = "Ratio: sale price vs. list price"
        metrics[metricsCount]= "N/A"
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "N/A"
        metricsUsage[metricsCount] = "Not Used"

        puts e.message
        puts e.backtrace.inspect
      end

      metricsCount += 1
      metricsNames[metricsCount] = "Future metrics: Supply side"
      metrics[metricsCount]= ""
      metricsPass[metricsCount] = true
      metricsComments[metricsCount]= "Days on market"
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "Change in home prices"
      metrics[metricsCount]= changeInHomePrice[:percent]
      metricsPass[metricsCount] = true
      metricsComments[metricsCount]= "Percentage change in home prices"
      metricsUsage[metricsCount] = "Not Used"

      metricsCount += 1
      metricsNames[metricsCount] = "One year change in home prices"
      metrics[metricsCount]= changeInHomePrice[:recentpercent]
      metricsPass[metricsCount] = true
      metricsComments[metricsCount]= "One year percentage change in home prices"
      metricsUsage[metricsCount] = "Not Used"      


      metricsCountBeginBlock = metricsCount
      begin
        urlsToHit.push("http://www.homesnap.com/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//state').content+"/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//city').content.to_s.gsub(" ","-")+"/"+@addresses[q].street.to_s.upcase.gsub(" RD", " ROAD").gsub(" LN", " LANE").gsub(" ST"," STREET").gsub(" DR", " DRIVE").gsub(" AVE", " AVENUE").gsub(" PL", " PLACE").gsub(" CT", " COURT").gsub(" BLVD", " BOULEVARD").gsub(" BL", " BOULEVARD").gsub(" CIR", " CIRCLE").gsub(" PKWY"," PARKWAY").gsub(" ","-"))        
        @page = Nokogiri::HTML(open("http://www.homesnap.com/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//state').content+"/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//city').content.to_s.gsub(" ","-")+"/"+@addresses[q].street.to_s.upcase.gsub(" RD", " ROAD").gsub(" LN", " LANE").gsub(" ST"," STREET").gsub(" DR", " DRIVE").gsub(" AVE", " AVENUE").gsub(" PL", " PLACE").gsub(" CT", " COURT").gsub(" BLVD", " BOULEVARD").gsub(" BL", " BOULEVARD").gsub(" CIR", " CIRCLE").gsub(" PKWY"," PARKWAY").gsub(" ","-")))
        metricsCount += 1
        metricsNames[metricsCount] = "Homescore"
        metrics[metricsCount]= @page.css("div[class='pfValue homescore']").text[0..1]
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Homescore"
        metricsUsage[metricsCount] = "Not Used"  

        metricsCount += 1
        metricsNames[metricsCount] = "Homesnap - Last Sale Date"
        begin
          metrics[metricsCount]= Date.strptime(@page.css("div[class='pfValue lastsaledate']").text, "%m/%d/%Y").to_s.sub(",", "")      
        rescue
          metrics[metricsCount]=@page.css("div[class='pfValue lastsaledate']").text.to_s.gsub(",","")
        end
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Homesnap's - Last Sale Date"
        metricsUsage[metricsCount] = "Not Used"  
      rescue
        metricsCount = metricsCountBeginBlock
        metricsCount += 1
        metricsNames[metricsCount] = "Homescore"
        metrics[metricsCount]= "Not Found"
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Homescore"
        metricsUsage[metricsCount] = "Not Used"  


        metricsCount += 1
        metricsNames[metricsCount] = "Homesnap - Last Sale Date"
        metrics[metricsCount]= "Not Found"   
        metricsPass[metricsCount] = true
        metricsComments[metricsCount]= "Homesnap's - Last Sale Date"
        metricsUsage[metricsCount] = "Not Used"  


        puts "Ended up in the homesnap rescue, typical"
      end





      if metricsPass[metricsNames.index("Last sold history")] == false
        reason[0]="Sold too recently"
      else
        reason[0]=nil
      end
      if (metricsPass[metricsNames.index("Distance to Neighbors")..metricsNames.index("Surrounding Census Tract Density")].count(false)) >= 2
        reason[1]="Too rural"
      else
        reason[1]=nil
      end
      if metricsPass[metricsNames.index("Average beds in community")..metricsNames.index("Average Price in community")].count(false) >= 2 
        reason[2]="Atypical property"
      else
        reason[2]=nil
      end
      if metricsPass[metricsNames.index("Zillow Comparable score")..metricsNames.index("Zillow Comparable count")].count(false) >= 2
        reason[3]="Illiquid market"
      else
        reason[3]=nil
      end
      if metricsPass[metricsNames.index("Zestimate")] == false
        reason[4]="out of $ range"
      else
        reason[4]=nil
      end
      if metricsPass[metricsNames.index("Property use")] == false
        reason[5]="Not single fam"
      else
        reason[5]=nil
      end      
      if metricsPass[metricsNames.index("Build Date (No new)")] == false
        reason[6]="New construction"
      else
        reason[6]=nil
      end
      if metricsPass[metricsNames.index("Pre-approval")] == false
        reason[7]="Not in MSAs"
      else
        reason[7]=nil
      end
      if metricsPass[metricsNames.index("Std. Dev. of price deltas")..metricsNames.index("Std. Dev. of historical home price")].count(false)>=2
        reason[8]="Prices volatile"
      else
        reason[8]=nil
      end
      if metricsPass[metricsNames.index("Schools")]==false
        reason[9]="Bad Schools"
      else
        reason[9]=nil
      end
      if (metricsPass[metricsNames.index("Distance from MSA")] || metricsPass[metricsNames.index("Second Distance from MSA")]) == false
        reason[10]="MSA Distance"
      else
        reason[10]=nil
      end
      if reason.compact.size == 0
        reason[11]="Approved"
      else
        reason[11]=nil
      end

      @newOutput = Output.new
      @newOutput.street = @addresses[q].street.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip
      @newOutput.citystatezip = @addresses[q].citystatezip.to_s.upcase.gsub(",","").gsub("+"," ").gsub("."," ").strip
      @newOutput.names = metricsNames
      @newOutput.numbers = metrics
      @newOutput.passes = metricsPass
      @newOutput.urls = urlsToHit
      @newOutput.reason = reason
      @newOutput.comments = metricsComments
      @newOutput.usage = metricsUsage
      @newOutput.zpid = @zpid.to_s
      @newOutput.runid = runID
      @newOutput.time = (Time.now-@startTime-@sectionTimes.inject(:+)).round
      @newOutput.save

      @sectionTimes.push((Time.now-@startTime-@sectionTimes.inject(:+)).round)
    end


    @allOutput = Output.all

    if params[:path] == nil
      return render 'getvalues'
    end

    @calcedurl = "/inspect/"+params[:street]+"/"+params[:citystatezip]
    return render 'blank'
  end

end