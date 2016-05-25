########################################################################
# This module holds all of the functions used to access the zillow api
# or website
# Date: 2016/04/21
# Author: Brad
########################################################################
module ZillowApi
  module_function

  # Constants
  ZILLOW_TOKEN = ApiTokens.zillow_key
  # ZILLOW_TOKEN = 'X1-ZWz1euzz31vnd7_5b1bv' # Neals Productions
  # ZILLOW_TOKEN = 'X1-ZWz19qut1tazuz_1fz14' # Brad Testing

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

    comps_data, comps_values, zillow_comps_url = getDeepComps(zpid.content, prop_lat, prop_lon)
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
    # prop_zillow_page, prop_url = getPropertyPage(zpid.content)
    # zillow_info[:propHtml] = prop_zillow_page
    # urls << prop_url

    # Add urls to hash
    zillow_info[:urls] = urls

    return zillow_info
  end

  # Function to collect important property data from zillow xml into a hash
  def getPropertyInfo(zillow_prop_xml)
    # Get objects (or nil if not present)
    estimate = zillow_prop_xml.at_xpath('//results//result//zestimate//amount')
    state = zillow_prop_xml.at_xpath('//results//address//state')
    zipCode = zillow_prop_xml.at_xpath('//results//address//zipcode')
    propType = zillow_prop_xml.at_xpath('//useCode')
    lastSoldDate = zillow_prop_xml.at_xpath("//response//results//result//lastSoldDate")
    buildYear = zillow_prop_xml.at_xpath('//yearBuilt')
    lat = zillow_prop_xml.at_xpath('//result//address//latitude')
    lon = zillow_prop_xml.at_xpath('//result//address//longitude')
    bd = zillow_prop_xml.at_xpath('//result//bedrooms')
    zpid = zillow_prop_xml.at_xpath('//zpid')
    propSqFt = zillow_prop_xml.at_xpath('//response//result//finishedSqFt')
    lotSqFt = zillow_prop_xml.at_xpath('//response//result//lotSizeSqFt')
    estimateHigh = zillow_prop_xml.at_xpath('//zestimate//valuationRange//high')
    estimateLow = zillow_prop_xml.at_xpath('//zestimate//valuationRange//low')

    # Extract data if not nil
    key_prop_data = {
      :estimate => estimate.nil? ? nil : estimate.content.to_f,
      :state => state.nil? ? nil : state.content.to_s,
      :zipCode => zipCode.nil? ? nil : zipCode.content.to_s,
      :propType => propType.nil? ? nil : propType.content.to_s,
      :lastSoldDate => lastSoldDate.nil? ? nil : lastSoldDate.content,
      :buildYear => buildYear.nil? ? nil : buildYear.content,
      :lat => lat.nil? ? nil : lat.content,
      :lon => lon.nil? ? nil : lon.content,
      :bd => bd.nil? ? nil : bd.content.to_i,
      :zpid => zpid.nil? ? nil : zpid.content,
      :propSqFt => propSqFt.nil? ? nil : propSqFt.content.to_f,
      :lotSqFt => lotSqFt.nil? ? nil : lotSqFt.content.to_f,
      :estimateHigh => estimateHigh.nil? ? nil : estimateHigh.content.to_f,
      :estimateLow => estimateLow.nil? ? nil : estimateLow.content.to_f
    }
    return key_prop_data
  end

  # Function to get property info xml based on an address
  def getPropertyDeepSearchResults(address)
    # Construct url
    esc_street = URI.escape(address.street)
    esc_csz = URI.escape(address.citystatezip)
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
    # Add bd/bath?
    comp_values = {:count => comps_data.size,
                   :scores => [],
                   :lastSoldDates => [],
                   :propSqFts => [],
                   :estimates => [],
                   :lotSizes => [],
                   :distances => []
                 }

    # Check to make sure we have comps, if not return the empty data
    if comps_data.nil? || comps_data.size == 0
      return comps_data, comp_values, URI.parse(base_url).to_s
    end

    # Loop over comps and extract necessary information
    comps_data.each do |c|
      # Score
      comp_values[:scores] << c.attribute('score').value.to_f

      # last sold date
      comp_last_sold = Nokogiri::XML(c.to_s).at_xpath('//lastSoldDate')
      if !comp_last_sold.nil?
        comp_values[:lastSoldDates] << Date.strptime(comp_last_sold.content, "%m/%d/%Y")
      end

      # Sqft
      comp_sqft = Nokogiri::XML(c.to_s).at_xpath('//finishedSqFt')
      comp_values[:propSqFts] << comp_sqft.content.to_f if !comp_sqft.nil?

      # Zestimate
      comp_zest = Nokogiri::XML(c.to_s).at_xpath('//zestimate//amount')
      comp_values[:estimates] << comp_zest.content.to_f if !comp_zest.nil?

      # Lot Size
      comp_lot_size = Nokogiri::XML(c.to_s).at_xpath('//lotSizeSqFt')
      comp_values[:lotSizes] << comp_lot_size.content.to_f if !comp_lot_size.nil?

      # Comp Distance
      comp_lat = Nokogiri::XML(c.to_s).at_xpath('//address//latitude').content
      comp_lon = Nokogiri::XML(c.to_s).at_xpath('//address//longitude').content
      if !comp_lat.nil? && !comp_lon.nil?
        comp_values[:distances] << GeoFunctions.getDistanceBetween(prop_lat, prop_lon, comp_lat, comp_lon)
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
    base_url = "http://www.zillow.com/webservice/GetDemographics.htm?zws-id=#{ZILLOW_TOKEN}&state=#{state}&city=#{city}&zipcode=#{zip}"

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