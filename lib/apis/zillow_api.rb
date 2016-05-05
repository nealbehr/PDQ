########################################################################
# This module holds all of the functions used to access the zillow api
# or website
# Date: 2016/04/21
# Author: Brad
########################################################################
module ZillowApi
  module_function

  # Constants
  ZILLOW_TOKEN = 'X1-ZWz1euzz31vnd7_5b1bv'

  # Function to collect all the zillow information for a give property
  # Returns a hash with the rax XML, deep comps data, urls to hit,
  # property html page, and neighborhood data (if gather)
  def collectZillowInfo(address, params)
    # Set up storage
    zillow_info = Hash.new
    urls = []

    # Get the DeepSearchResults XML (save url and body for debugging section)
    raw_prop_data, zillow_prop_url, res_body = getPropertyDeepSearchResults(address)
    zillow_info[:propRawXml] = raw_prop_data
    urls.push(zillow_prop_url, res_body)

    # Check if the property was found, if not, return XML as is
    zpid = raw_prop_data.at_xpath('//zpid')
    zestimate = raw_prop_data.at_xpath('//results//result//zestimate//amount')
    return zillow_info if (zpid.nil? || zestimate.nil?)

    # Get comps from Zillow
    prop_lat = raw_prop_data.at_xpath('//results//latitude').content
    prop_lon = raw_prop_data.at_xpath('//results//longitude').content

    comps_data, comps_values, zillow_comps_url = getDeepComps(zpid, prop_lat, prop_lon)
    zillow_info[:compsData] = comps_data
    zillow_info[:compsKeyValues] = comps_values
    urls << zillow_comps_url

    # Get neighborhood stats (if applicable)
    if params[:path] == 'gather'
      neigh_data, zillow_neigh_url = getDemographics(raw_prop_data)
      zillow_info[:neighborhood] = neigh_data
      urls << zillow_neigh_url
    end

    # Get property html page
    prop_zillow_page, prop_url = getPropertyPage(zpid)
    zillow_info[:propHtml] = neigh_data
    urls << prop_url

    # Add urls to hash
    zillow_info[:urls] = urls

    return zillow_info
  end

  # Function to collect important property data from zillow xml into a hash
  def getPropertyInfo(zillow_prop_xml)
    key_prop_data = {
      :propEstimate => prop_data.at_xpath('//results//result//zestimate//amount').content,
      :propState => prop_data.at_xpath('//results//address//state').content.to_s,
      :propUrbanCode => prop_data.at_xpath('//results//address//zipcode').content.to_i,
      :propType => prop_data.at_xpath('//useCode').content,
      :propLastSold => prop_data.at_xpath("//response//results//result//lastSoldDate"),
      :propBuildYear => prop_data.at_xpath('//yearBuilt').content,
      :lat => prop_data.at_xpath('//result//address//latitude').content,
      :lon => prop_data.at_xpath('//result//address//longitude').content,
      :bd => prop_data.at_xpath('//result//bedrooms').content.to_i,
      :zpid => prop_data.at_xpath('//zpid').content,
      :propSqFt => prop_data.at_xpath('//response//result//finishedSqFt').content.to_f,
      :lotSqFt => prop_data.at_xpath('//response//result//lotSizeSqFt').content.to_f,
      :estimateHigh => prop_data.at_xpath('//zestimate//valuationRange//high').content.to_f,
      :estimateLow => prop_data.at_xpath('//zestimate//valuationRange//low').content.to_f
    }
    return key_prop_data
  end

  # Function to get property info xml based on an address
  def getPropertyDeepSearchResults(address)
    # Construct url
    esc_street = URI.escape(MiscFunctions.addressStringClean(address.street))
    esc_csz = URI.escape(MiscFunctions.addressStringClean(address.citystatezip))
    base_url = "http://www.zillow.com/webservice/GetDeepSearchResults.htm?zws-id=#{ZILLOW_TOKEN}" 
    base_url += "&address=#{esc_street}&citystatezip=#{esc_csz}"

    # Create response
    res = getUrlResponse(base_url)

    # Parse xml
    prop_info = Nokogiri::XML(res.body)

    # Return info
    return prop_info, URI.parse(base_url).to_s.gsub(",","THESENTINEL"), res.body
  end

  # Function to get and return the deep comps
  def getDeepComps(zpid, prop_lat, prop_lon)
    # Construct url and create response
    base_url = "http://www.zillow.com/webservice/GetDeepComps.htm?zws-id=#{ZILLOW_TOKEN}&zpid=#{zpid}&count=25"
    res = getUrlResponse(base_url)

    # Parse XML and extract comp portion
    compOutput = Nokogiri::XML(res.body)
    comps_data = compOutput.xpath("//response//properties//comparables//comp")

    # Collect values for typicality
    comp_values = {:compsCount => comps_data.size,
                   :compsScore => [],
                   :compsLastSold => [],
                   :compsSqFt => [],
                   :compsZestimate => [],
                   :compsLotSize => [],
                   :compsDistance => []
                 }

    # Check to make sure we have comps, if not return the empty data
    if comps_data.nil? || comps_data.size == 0
      return comps_data, comp_values, URI.parse(base_url).to_s
    end

    # Loop over comps and extract necessary information
    comps_data.each do |c|
      # Score
      comp_values[:compsScore] << c.attribute('score').value.to_f

      # last sold date
      comp_last_sold = Nokogiri::XML(c.to_s).at_xpath('//lastSoldDate')
      if !comp_last_sold.nil?
        comp_values[:compsLastSold] << Date.strptime(comp_last_sold.content, "%m/%d/%Y")
      end

      # Sqft
      comp_sqft = Nokogiri::XML(c.to_s).at_xpath('//finishedSqFt').content.to_f
      comp_values[:compsSqFt] << comp_sqft.content.to_f if !comp_sqft.nil?

      # Zestimate
      comp_zest = Nokogiri::XML(c.to_s).at_xpath('//zestimate//amount')
      comp_values[:compsZestimate] << comp_zest.content.to_f if !comp_zest.nil?

      # Lot Size
      comp_lot_size = Nokogiri::XML(c.to_s).at_xpath('//lotSizeSqFt')
      comp_values[:compsLotSize] << comp_lot_size.content.to_f if !comp_lot_size.nil?

      # Comp Distance
      comp_lat = Nokogiri::XML(@comparables[x].to_s).at_xpath('//address//latitude')
      comp_lon = Nokogiri::XML(@comparables[x].to_s).at_xpath('//address//longitude')
      if !comp_lat.nil? && !comp_lon.nil?
        comp_values[:compsDistance] << GeoFunctions.getDistanceBetween(prop_lat, prop_lon, comp_lat, comp_lon)
      end
    end

    # Return info
    return comps_data, comp_values, URI.parse(base_url).to_s
  end

  # Function to get the demographics from Zillow (only used if 'gather')
  def getDemographics(prop_data)
    # Construct url
    state = prop_data.at_xpath('//result//address//state').content
    city = URI.escape(prop_data.at_xpath('//result//address//city').content)
    zip = prop_data.at_xpath('//result//address//zipcode').content
    base_url = "http://www.zillow.com/webservice/GetDemographics.htm?zws-id=#{ZILLOW_TOKEN}" 
    base_url += "&state=#{state}&city=#{city}&zipcode=#{zip}"

    # Create response
    res = getUrlResponse(base_url)

    # Parse XML
    neighborhoodOutput = Nokogiri::XML(res.body)

    return neighborhoodOutput, URI.parse(base_url).to_s
  end

  # Get the property page html
  def getPropertyPage(zpid)
    base_url = "http://www.zillow.com/homes/#{zpid}_zpid/"
    page = Nokogiri::HTML(open(base_url))
    return page, URI.parse(base_url).to_s
  end

  # Common function to take a url and return the response
  def getUrlResponse(base_url)
    url = URI.parse(base_url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }
    return res
  end

  # Function to scrape neighbors data from the carousel
  def neighborsScrape(output, zpid)
    # Construct URL and get response
    base_url = "http://www.zillow.com/homes/#{zpid}_zpid/"
    res = getUrlResponse(base_url)
    page = res.body

    # Create storage
    scrappingTable = Array.new
    prices = Array.new
    bedrooms = Array.new
    bathrooms = Array.new
    sqft = Array.new    

    output[:urlsToHit] << "Debugging"

    pageTruncated = page.to_s.split('zsg-carousel-scroll-wrapper')[0]
    scrappingProperties = pageTruncated.to_s.split('zsg-photo-card-caption')

    # Loop over properties in the carousel
    for x in 0 .. scrappingProperties.length - 1
      scrappingTable[x] = scrappingProperties[x].to_s.gsub("zsg-photo-card-price","||DELIMITER||").gsub("zsg-photo-card-info","||DELIMITER||").gsub("zsg-photo-card-notification","||DELIMITER||").gsub("zsg-photo-card-address hdp-link noroute","||DELIMITER||").gsub("zsg-photo-card-actions","||DELIMITER||")

      scrappingTable[x] = scrappingTable[x].split("||DELIMITER||")

      if x >= 1 && scrappingTable[x][1] != nil
        begin
          prices.push(scrappingTable[x][1].to_s[2..11].gsub("<","").gsub("s","").gsub("p","").gsub("/","").gsub("$","").gsub(",","").to_i)
        rescue
         output[:urlsToHit] << "Had an error with the pricing scrape!"
        end

        begin
          bedrooms.push(scrappingTable[x][2].to_s[2].to_i)
        rescue
        end

        begin
          end_ind = scrappingTable[x][2].to_s.index("ba").to_i
          start_ind = end_ind - 4 
          bathrooms.push(scrappingTable[x][2][start_ind..end_ind].gsub(";","").gsub(" ","").gsub("b","").gsub(">","").to_i)  
        rescue
        end

        begin
          end_ind = scrappingTable[x][2].to_s.index("sqft").to_i
          start_ind = end_ind - 6

          tempVar = scrappingTable[x][2].to_s[start_ind..end_ind].gsub(";","").gsub(" ","").gsub("b","").gsub("k","").gsub("s","").gsub(",","").to_f*1000

          if tempVar > 100000
            tempVar = tempVar/1000
          end

          sqft.push(tempVar)  
        rescue
        end          
      end 
    end

    # Create storage
    results = {:totalPrice => 0,
               :totalBedrooms => 0,
               :totalBathrooms => 0,
               :totalSqFt => 0,
               :totalPriceCount => 0,
               :totalBedroomsCount => 0,
               :totalBathroomsCount => 0,
               :totalSqFtCount => 0,            
               :pricesString => "",
               :bathroomsString => "",
               :bedroomsString => "",
               :sqftString => ""
             }
    
    # Gather values
    for x in 0 .. scrappingProperties.length - 1
      if prices[x] != 0 && prices[x] != nil
        results[:totalPrice] += prices[x]
        if prices[x] != 0 
          results[:totalPriceCount] += 1
        end
        results[:totalBathrooms] += bathrooms[x]
        if bathrooms[x] != 0 
          results[:totalBathroomsCount] += 1
        end
        results[:totalBedrooms] += bedrooms[x]
        if bedrooms[x] != 0 
          results[:totalBedroomsCount] += 1
        end
        results[:totalSqFt] += sqft[x]
        if sqft[x] != 0 
          results[:totalSqFtCount] += 1
        end

        results[:pricesString] = results[:pricesString].to_s + " ;; " + prices[x].to_s
        results[:bathroomsString] = results[:bathroomsString].to_s + " ;; " + bathrooms[x].to_s
        results[:bedroomsString] = results[:bedroomsString].to_s + " ;; " + bedrooms[x].to_s
        results[:sqftString] = results[:sqftString].to_s + " ;; " + sqft[x].to_s                              
      end
    end

    return results
  end

end