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


    @addresses = Address.all
    @allData = Array.new
    distanceThreshold = 1000

    @startTime = Time.now
    @sectionTimes = Array.new
        
    for q in 0..@addresses.size-1
      metrics = Array.new
      metricsNames = Array.new
      metricsPass = Array.new
      metricsComments = Array.new
      urlsToHit = Array.new
      reason = Array.new
      url = URI.parse('http://www.zillow.com/webservice/GetDeepSearchResults.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&address='+URI.escape(@addresses[q].street)+'&citystatezip='+URI.escape(@addresses[q].citystatezip))
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      @evalProp = Nokogiri::XML(res.body)
      urlsToHit[0]=url

puts @evalProp

      if @evalProp.at_xpath('//zpid') == nil || @evalProp.at_xpath('//results//result//zestimate//amount') == nil
        metricsNames[0] = "ZILLOW API FAIL"
        metrics[0]= "PROPERTY NOT FOUND"
        metricsPass[0] = false
        metricsComments[0]= "PROPERTY NOT FOUND"
        reason.push("NOT FOUND BY ZILLOW")
        @allData[q] = { names: metricsNames, numbers: metrics, passes: metricsPass, urls: urlsToHit, reason: reason, comments: metricsComments}
        next
      end
      @zpid = @evalProp.at_xpath('//zpid').content

      url = URI.parse('http://www.zillow.com/webservice/GetDeepComps.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&zpid='+@zpid+'&count=25')
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      @compOutput = Nokogiri::XML(res.body)
      urlsToHit[1]=url

      url = URI.parse('http://www.zillow.com/webservice/GetDemographics.htm?zws-id=X1-ZWz1euzz31vnd7_5b1bv&state='+@evalProp.at_xpath('//result//address').at_xpath('//state').content+'&city='+URI.escape(@evalProp.at_xpath('//result//address').at_xpath('//city').content)+"&zipcode="+@evalProp.at_xpath('//result//address').at_xpath('//zipcode').content)
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      @evalNeighborhood = Nokogiri::XML(res.body)
      urlsToHit[2]=url




      metricsNames[0] = "Price"
      metrics[0]=@evalProp.at_xpath('//results//result//zestimate//amount').content
      metricsPass[0] = metrics[0].to_i < 5000000 && metrics[0].to_i > 300000
      metricsComments[0]= "< 5000000 & > 300000"


      metricsNames[1] = "Investment Location"
      metrics[1]=@evalProp.at_xpath('//results//address//zipcode').content
      metricsPass[1] = Approved.find_by(zipcode: metrics[1])!=nil
      if metricsPass[1]
        metricsComments[1]= "Found in database. Mapped to: " + Approved.find_by(zipcode: metrics[1])[:status].to_s
      else 
        metricsComments[1]= "Not Found in database"
      end

      metricsNames[2] = "Urban Density"
      metrics[2]= Density.find_by(zipcode: metrics[1])[:densityofzip]
      metricsPass[2] = metrics[2].to_f > 150
      metricsComments[2]= "> 150"

      if @evalProp.at_xpath("//response//results//result//lastSoldDate") == nil
        metricsNames[3] = "Last sold history"
        metrics[3]= "Not available"
        metricsPass[3] = false
        metricsComments[3]= "NA"
      else
        metricsNames[3] = "Last sold history"
        metrics[3]= Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y").to_s.sub(",", "")
        metricsPass[3] = Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y") < Date.today - 365
        metricsComments[3]= "Time from today: " + ((Date.strptime(@evalProp.at_xpath("//response//results//result//lastSoldDate").content, "%m/%d/%Y") - Date.today).to_i * -1).to_s + " days"
      end
      if @compOutput.xpath("//response//properties//comparables//comp")!= nil
        @comparables = @compOutput.xpath("//response//properties//comparables//comp")
        total = 0
        for x in 0..@comparables.size-1
          total += @comparables[x].attribute('score').value.to_f
        end

        metricsNames[4] = "Zillow Comparable score"
        metrics[4]= total/@comparables.size.to_f
        metricsPass[4] = total/@comparables.size.to_f > 6.0
        metricsComments[4]= " > 6.0"

        metricsNames[5] = "Zillow Comparable count"
        metrics[5]= @comparables.size.to_i
        metricsPass[5] = @comparables.size.to_i > 4
        metricsComments[5]= "> 4"
      else
        metricsNames[4] = "Zillow Comparable score"
        metrics[4]= "Comps not found"
        metricsPass[4] = false
        metricsComments[4]= "NA"

        metricsNames[5] = "Zillow Comparable count"
        metrics[5]= "Comps not found"
        metricsPass[5] = false
        metricsComments[5]= "NA"
      end
      @page = Nokogiri::HTML(open("http://www.zillow.com/homes/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content+"_zpid/"))
      scrappingtable = @page.css('div#hdp-unit-list').css('td')
 
      urlsToHit[3] = "http://www.zillow.com/homes/"+@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content+"_zpid/"

@sectionTimes.push(Time.now-@startTime)

      @distance = Array.new
      totalPrice = 0
      totalBeds = 0
      totalBaths = 0
      totalSqFt = 0
      totalRecords = 0
      totalDistance = 0
      totalDistanceCount = 0
      for x in 0..scrappingtable.size/5-1
        skipflag = false
        url = URI.parse("http://rpc.geocoder.us/service/json?address="+URI.escape(scrappingtable[5*x+0].content))
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        urlsToHit[4+x] = "Success: " + url.to_s
        textOutput = res.body
        if textOutput.include? "500 Internal Server Error"
          url = "https://maps.googleapis.com/maps/api/geocode/xml?address=" + URI.escape(scrappingtable[5*x+0].content)+ "&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
          geocoderOutput = Nokogiri::XML(open(url))
          if geocoderOutput.at_xpath('//location_type') == nil
            skipflag = true
            urlsToHit[4+x] = "GoogleFail: " + url
          elsif geocoderOutput.at_xpath('//location_type').content.include? "ROOFTOP"
            lat2 = geocoderOutput.at_xpath('//location//lat').content
            lon2 = geocoderOutput.at_xpath('//location//lng').content
            urlsToHit[4+x] = "Google: " + url            
          else
            skipflag = true
            urlsToHit[4+x] = "GoogleFail: " + url            
          end
        else
          jsonOutput = JSON.parse(textOutput)
          lat2 = jsonOutput[0]["lat"].to_f
          lon2 = jsonOutput[0]["long"].to_f
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
            urlsToHit[4+x] = "Recheck: " + url
            geocoderOutput = Nokogiri::XML(open(url))
            if geocoderOutput.at_xpath('//location_type') == nil
              urlsToHit[urlsToHit.size] = "GoogleFail: " + url
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
              urlsToHit[4+x] = "GoogleFail: " + url      
              next
            end
          end
          @distance[x] = d
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
      if @evalProp.at_xpath('//response//result//bedrooms') != nil
        metricsNames[6] = "Average beds in community"
        metrics[6]= @evalProp.at_xpath('//response//result//bedrooms').content.to_f / (totalBeds.to_f/totalRecords.to_f)
        metricsPass[6] = metrics[6] < 1.25 && metrics[6] > 0.75
        metricsComments[6] = "Prop: " + @evalProp.at_xpath('//response//result//bedrooms').content.to_s + "  || Avg: " + (totalBeds.to_f/totalRecords.to_f).to_s
      else
        metricsNames[6] = "Average beds in community"
        metrics[6] = "Not available"
        metricsPass[6] = false
        metricsComments[6]= "NA"
      end
      if @evalProp.at_xpath('//response//result//bathrooms')!= nil
        metricsNames[7] = "Average baths in community"
        metrics[7]= @evalProp.at_xpath('//response//result//bathrooms').content.to_f / (totalBaths.to_f/totalRecords.to_f)
        metricsPass[7] = metrics[7] < 1.25 && metrics[7] > 0.75
        metricsComments[7]=  "Prop: " + @evalProp.at_xpath('//response//result//bathrooms').content.to_s + "  || Avg: " + (totalBaths.to_f/totalRecords.to_f).to_s
      else
        metricsNames[7] = "Average beds in community"
        metrics[7] = "Not available"
        metricsPass[7] = false
        metricsComments[7]= "NA"
      end

      if @evalProp.at_xpath('//response//result//finishedSqFt') != nil
        metricsNames[8] = "Average SqFt in community"
        metrics[8]= @evalProp.at_xpath('//response//result//finishedSqFt').content.to_f / (totalSqFt.to_f/totalRecords.to_f)
        metricsPass[8] = metrics[8] < 1.40 && metrics[8] > 0.60
        metricsComments[8]= "Prop: " + @evalProp.at_xpath('//response//result//finishedSqFt').content.to_s + "  || Avg: " + (totalSqFt.to_f/totalRecords.to_f).to_s
      else
        metricsNames[8] = "Average beds in community"
        metrics[8] = "Not available"
        metricsPass[8] = false
        metricsComments[8]= "NA"
      end

      metricsNames[9] = "Average Price in community"
      metrics[9]= @evalProp.at_xpath('//response//result//zestimate//amount').content.to_f / (totalPrice.to_f/totalRecords.to_f)
      metricsPass[9] = metrics[9] < 1.40 && metrics[9]  > 0.60
      metricsComments[9]= "Prop: " + @evalProp.at_xpath('//response//result//zestimate//amount').content.to_s + "  || Avg: " + (totalPrice.to_f/totalRecords.to_f).to_s

      if @evalProp.at_xpath('//useCode') == nil
        metricsNames[10] = "Property use"
        metrics[10]= "Not available"
        metricsPass[10] = false
        metricsComments[10]= "NA"
      else
        metricsNames[10] = "Property use"
        metrics[10]= @evalProp.at_xpath('//useCode').content
        metricsPass[10] = metrics[10]=="SingleFamily"
        metricsComments[10]= "Has to be Single family"
      end

      if @evalProp.at_xpath('//yearBuilt') == nil
        metricsNames[11] = "Build Date (No new)"
        metrics[11]= "Not available"
        metricsPass[11] = false
        metricsComments[11]= "NA"
      else
        metricsNames[11] = "Build Date (No new)"
        metrics[11]= @evalProp.at_xpath('//yearBuilt').content
        metricsPass[11] = metrics[11].to_i < Time.now.year
        metricsComments[11]= "Can't be built this year"
      end

      begin
        metricsNames[12] = "Zestimate confidence"
        metrics[12]= (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100).to_s
        metricsPass[12] = (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100) < 30
        metricsComments[12] =  @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_s + "  -  " + @evalProp.at_xpath('//zestimate//valuationRange//high').content.to_s + "  ||  " + (((@evalProp.at_xpath('//zestimate//valuationRange//high').content.to_f - @evalProp.at_xpath('//zestimate//valuationRange//low').content.to_f) / metrics[0].to_f).round(2)*100).to_s + "%"
      rescue StandardError=>e
        metricsNames[12] = "Zestimate Confidence"
        metics[12] = "Not available"
        metricsPass[12] = false
        metricsComments[12]= "NA"
      end

      metricsNames[13] = "Distance to Neighbors"
      metrics[13]= totalDistance.to_f/totalDistanceCount.to_f
      metricsPass[13] = totalDistance.to_f/totalDistanceCount.to_f < 700
      metricsComments[13]= "< 700"

      metricsNames[14] = "Number of Neighbors"
      metrics[14]= totalDistanceCount.to_f
      metricsPass[14] = totalDistanceCount.to_f>15
      metricsComments[14]= "> 15"

      metricsNames[15] = "Furthest Neighbor"
      metrics[15]= @distance.map(&:to_f).max
      metricsPass[15] = metrics[15].to_f < distanceThreshold
      metricsComments[15]= "< " + distanceThreshold.to_s

@sectionTimes.push(Time.now-@startTime-@sectionTimes.inject(:+))

      loopCounter = 0
      loop do
        url = URI.parse("http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x="+@evalProp.at_xpath('//result//address//longitude').content+"&y="+@evalProp.at_xpath('//result//address//latitude').content+"&benchmark=9&vintage=910&format=json")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        @jsonOutputArea = JSON.parse(res.body)
        urlsToHit[urlsToHit.size] = url


        break if loopCounter>10 || @jsonOutputArea["result"]["geographies"]["Census Tracts"] != nil
        loopCounter += 1
      end
      
      url = URI.parse("http://api.census.gov/data/2010/sf1?get=H0030001&for=tract:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["STATE"]+"+county:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["COUNTY"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
      req = Net::HTTP::Get.new(url)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      jsonOutputHouseholds = JSON.parse(res.body)
      urlsToHit[urlsToHit.size] = url
      metricsNames[16] = "Census Tract Density"
      metrics[16]= jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)
      metricsPass[16] = jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)>500
      metricsComments[16]= "Density of Census Tract: " + @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"].to_s

@sectionTimes.push(Time.now-@startTime-@sectionTimes.inject(:+))

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
        loopCounter = 0
        loop do
          url = URI.parse("http://geocoding.geo.census.gov/geocoder/geographies/coordinates?x="+(startingX+cordAdj[x][:xadj]).to_s+"&y="+(startingY+cordAdj[x][:yadj]).to_s+"&benchmark=9&vintage=910&format=json")
          req = Net::HTTP::Get.new(url)
          res = Net::HTTP.start(url.host, url.port) {|http|
            http.request(req)
          }
          @jsonOutputArea = JSON.parse(res.body)
          urlsToHit[urlsToHit.size] = url
          break if loopCounter>10 || @jsonOutputArea["result"]["geographies"]["Census Tracts"] != nil
          loopCounter += 1
        end

        url = URI.parse("http://api.census.gov/data/2010/sf1?get=H0030001&for=tract:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"]+"&in=state:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["STATE"]+"+county:"+@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["COUNTY"]+"&key=e07fac6d4f1148f54c045fe81ce1b7d2f99ad6ac")
        req = Net::HTTP::Get.new(url)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        jsonOutputHouseholds = JSON.parse(res.body)
        urlsToHit[urlsToHit.size] = url
        if @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"] == 0
          next
        end
        censusTractDensities.push({censustract: @jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["TRACT"], tractdensity: jsonOutputHouseholds[1][0].to_f / (@jsonOutputArea["result"]["geographies"]["Census Tracts"][0]["AREALAND"].to_f/2589990.0)})

      end

      puts censusTractDensities
      metricsNames[17] = "Surrounding Census Tract Density"
      metrics[17]= censusTractDensities.sort_by { |holder| holder[:tractdensity] }[0][:tractdensity]
      metricsPass[17] = !( (censusTractDensities.count{|holder| holder[:tractdensity] == metrics[17]} > 2 && metrics[17]<20) || (metrics[17] < 10))
      metricsComments[17]= "Census Tract: "+ censusTractDensities.sort_by { |holder| holder[:tractdensity] }[0][:censustract].to_s + " in " +censusTractDensities.count{|holder| holder[:tractdensity] == metrics[17]}.to_s + " of 8 directions. Total of " + (censusTractDensities.uniq.size).to_s + " tested."

      @sectionTimes.push(Time.now-@startTime-@sectionTimes.inject(:+))

      begin

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=3500&types=bank&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url
        googlePlacesOutput = Nokogiri::XML(open(url))

        metricsNames[18] = "Banks"
        metrics[18]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[18] = metrics[18]>0
        metricsComments[18]= "Banks within 3500 meters (~2 miles)"

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=3500&types=grocery_or_supermarket&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url
        googlePlacesOutput = Nokogiri::XML(open(url))

        metricsNames[19] = "Grocery Stores"
        metrics[19]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[19] = metrics[19]>0
        metricsComments[19]= "Grocery stores or supermarkets within 3500 meters (~2 miles)"

        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/xml?location="+@evalProp.at_xpath('//result//latitude').content+","+@evalProp.at_xpath('//result//longitude').content+"&radius=16000&types=restaurant&minprice=3&key=AIzaSyBXyPuglN-wH5WGaad7o1R7hZsOzhHCiko"
        urlsToHit[urlsToHit.size] = url
        googlePlacesOutput = Nokogiri::XML(open(url))

        metricsNames[20] = "Nice restaurants"
        metrics[20]=googlePlacesOutput.xpath('//PlaceSearchResponse//result').count
        metricsPass[20] = metrics[20]>0
        metricsComments[20]= "Restaurants with an expensive rating of 3 or more within 16000 meters (~10 miles)"


        url = URI.parse("http://api.walkscore.com/score?format=json&lat="+@evalProp.at_xpath('//result//latitude').content+"&lon="+@evalProp.at_xpath('//result//longitude').content+"&wsapikey=8895883fa0b4f996d0344ccee841e098")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        textOutput = res.body
        urlsToHit[urlsToHit.size] = url
        walkScore = JSON.parse(textOutput)

        metricsNames[21] = "Walk Score"
        metrics[21]=walkScore["walkscore"]
        metricsPass[21] = metrics[21]>0
        metricsComments[21]= "Walk Score's proprietary measure of neighborhood walkability"

        url = URI.parse("http://transit.walkscore.com/transit/score/?lat="+@evalProp.at_xpath('//result//latitude').content+"&lon="+@evalProp.at_xpath('//result//longitude').content+"&city=Seattle&state=WA&wsapikey=8895883fa0b4f996d0344ccee841e098")
        req = Net::HTTP::Get.new(url.to_s)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
        textOutput = res.body
        urlsToHit[urlsToHit.size] = url
        transitScore = JSON.parse(textOutput)

        metricsNames[22] = "Transit Score"
        metrics[22]=transitScore["transit_score"]
        metricsPass[22] = metrics[22]>0
        metricsComments[22]= "Walk Score's proprietary measure of neighborhood public transit"

        @sectionTimes.push(Time.now-@startTime-@sectionTimes.inject(:+))

        url = URI.parse("http://www.zillow.com/ajax/homedetail/HomeValueChartData.htm?mt=1&zpid="+URI.escape(@evalProp.at_xpath('//response').at_xpath('//results').at_xpath('//result').at_xpath('//zpid').content)+"&format=json")
        req = Net::HTTP::Get.new("http://www.zillow.com"+url.request_uri)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }

        urlsToHit[urlsToHit.size] = url
        jsonOutput = JSON.parse(Nokogiri::HTML(open(url)).css('p')[0].content)
        urlsToHit[urlsToHit.size] = [jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min
        @differencesInPrices = Array.new
        @neighborhoodPrices = Array.new
        @homePrices = Array.new
        for time in 0..[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-1
          @differencesInPrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[0]["points"][jsonOutput[0]["points"].size-1-time]["y"]-jsonOutput[1]["points"][jsonOutput[1]["points"].size-1-time]["y"]

          @neighborhoodPrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[0]["points"][jsonOutput[0]["points"].size-1-time]["y"]

          @homePrices[[jsonOutput[0]["points"].size, jsonOutput[1]["points"].size].min-time-1] = jsonOutput[1]["points"][jsonOutput[1]["points"].size-1-time]["y"]
        end

        metricsNames[23] = "Std. Dev. of price deltas"
        metrics[23]= @differencesInPrices.standard_deviation.round
        metricsPass[23] = metrics[23]>0
        metricsComments[23]= "Standard Deviation of price differences from neighborhood"

        metricsNames[24] = "Average of price deltas"
        metrics[24]= @differencesInPrices.average.round
        metricsPass[24] = metrics[24]>0
        metricsComments[24]= "Mean of price difference from neighborhood"

        metricsNames[25] = "Range of price deltas"
        metrics[25]= @differencesInPrices.range.round
        metricsPass[25] = metrics[25]>0
        metricsComments[25]= "Total range of price difference from neighborhood"

        urlsToHit.push(@differencesInPrices)
        urlsToHit.push(@neighborhoodPrices)        
        urlsToHit.push(@homePrices)

      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end


      if metricsPass[3] == false
        reason[0]="Sold too recently"
      else
        reason[0]=nil
      end
      if (metricsPass[13..15].count(false) + (metricsPass[2] ? 1 : 0) + metricsPass[16..17].count(false)) >= 2
        reason[1]="Too rural"
      else
        reason[1]=nil
      end
      if metricsPass[6..9].count(false) >= 2
        reason[2]="Atypical property"
      else
        reason[2]=nil
      end
      if metricsPass[4..5].count(false) >= 2
        reason[3]="Illiquid market"
      else
        reason[3]=nil
      end
      if metricsPass[0] == false
        reason[4]="Outside of price range"
      else
        reason[4]=nil
      end
      if metricsPass[10] == false
        reason[5]="Not a single family home"
      else
        reason[5]=nil
      end      
      if metricsPass[11] == false
        reason[6]="New construction - auto-review"
      else
        reason[6]=nil
      end
      if metricsPass[1] == false
        reason[7]="Not in MSAs"
      else
        reason[7]=nil
      end
      if reason.compact.size == 0
        reason[8]="Approved"
      else
        reason[8]=nil
      end

      @allData[q] = { names: metricsNames, numbers: metrics, passes: metricsPass, urls: urlsToHit, reason: reason, comments: metricsComments}

    end

@sectionTimes.push(Time.now-@startTime-@sectionTimes.inject(:+))
@sectionTimes.push(@sectionTimes.inject(:+))

    render 'getvalues'

  end

end