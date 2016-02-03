class AddressesController < ApplicationController

  def test
    ############################################################
    #                                                          #
    #  Feel free to delete test, it's just for messing with    #
    #                                                          #
    ############################################################
    puts "This is your IP"
    puts request.remote_ip  
    puts "Your IP is above"

    url = URI.parse('http://www.zillow.com/homes/20564792_zpid/')
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    @page = res.body

    @scrappingTable = Array.new
    @prices = Array.new
    @bedrooms = Array.new
    @bathrooms = Array.new
    @sqft = Array.new    


    @scrappingProperties = @page.to_s.split('zsg-photo-card-caption')
    for x in 0 .. @scrappingProperties.length - 1
      @scrappingTable[x] = @scrappingProperties[x].to_s.gsub("zsg-photo-card-price","||DELIMITER||").gsub("zsg-photo-card-info","||DELIMITER||").gsub("zsg-photo-card-notification","||DELIMITER||").gsub("zsg-photo-card-address hdp-link noroute","||DELIMITER||").gsub("zsg-photo-card-actions","||DELIMITER||")
      @scrappingTable[x] = @scrappingTable[x].split("||DELIMITER||")
      if x >= 1 && @scrappingTable[x][1] != nil
        begin
          @prices.push(@scrappingTable[x][1].to_s[2..11].gsub("<","").gsub("s","").gsub("p","").gsub("/","").gsub("$","").gsub(",","").to_i)
        rescue
        end
        begin
          @bedrooms.push(@scrappingTable[x][2].to_s[2..2].to_i)
        rescue
        end
        ?|
        begin
          @bathrooms.push(@scrappingTable[x][2].to_s[@scrappingTable[x][2].to_s.index("ba").to_i-4..@scrappingTable[x][2].to_s.index("ba").to_i].gsub(";","").gsub(" ","").gsub("b","").to_i)      
        rescue
        end
        begin
          @bathrooms.push(@scrappingTable[x][2].to_s[@scrappingTable[x][2].to_s.index("ba").to_i-4..@scrappingTable[x][2].to_s.index("ba").to_i].gsub(";","").gsub(" ","").gsub("b","").to_i)      
        rescue
        end
      end 
    end
    @totalPrice = 0
    @totalBedrooms = 0
    @totalBathrooms = 0
    @totalCount = 0
    for x in 0 .. @scrappingProperties.length - 1
      if @prices[x] != 0 && @bedrooms[x] != 0 && x >= 1 && @scrappingTable[x][1] != nil && @prices[x] != nil
        @totalPrice += @prices[x]
        @totalBathrooms += @bathrooms[x]
        @totalBedrooms += @bedrooms[x]
        @totalCount += 1
      end
    end

    render 'test'
  end

  def index
    @addresses = Address.all
  end


  def index
    @addresses = Address.all
  end

  def show
    @address = Address.find_by(id: params[:id])
  end

  def new
  end

  def create
    @address = Address.new
    @address.street = URI.unescape(params[:street].to_s.upcase.gsub(",","").gsub("+"," ").strip)
    @address.citystatezip = URI.unescape(params[:citystatezip].to_s.upcase.gsub(",","").gsub("+"," ").strip)

    if @address.save
      redirect_to addresses_url, notice: "Address created successfully."
    else
      render 'new'
    end
  end

  def edit
    @address = Address.find_by(id: params[:id])
  end

  def update
    @address = Address.find_by(id: params[:id])
    @address.street = params[:street]
    @address.citystatezip = params[:citystatezip]

    if @address.save
      redirect_to addresses_url, notice: "Address updated successfully."
    else
      render 'edit'
    end
  end

  def destroy
    @address = Address.find_by(id: params[:id])
    @address.destroy

    redirect_to addresses_url, notice: "Address deleted."
  end

  def destroyall
    @address = Address.all
    @address.each do |worker|
      worker.destroy
    end

    redirect_to addresses_url, notice: "All Addresses Deleted."
  end

end
