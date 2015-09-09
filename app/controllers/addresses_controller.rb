class AddressesController < ApplicationController

  def test
    render 'test'
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
