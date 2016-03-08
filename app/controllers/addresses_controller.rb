class AddressesController < ApplicationController
require 'basecrm'


  def test
    ############################################################
    #                                                          #
    #  Feel free to delete test, it's just for messing with    #
    #                                                          #
    ############################################################
    @basecrmToken = "9878d89068634f382f7233bb17091c244eab66b373f001b2ce1af00b67fe9b28"

    client = BaseCRM::Client.new(access_token: @basecrmToken)
    @testLO = client.contacts.where(email: "gregory.hill@banchomeloans.com")

     https://hooks.slack.com/services/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 

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
