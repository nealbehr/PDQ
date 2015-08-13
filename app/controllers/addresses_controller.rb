class AddressesController < ApplicationController

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
    @address.street = params[:street]
    @address.citystatezip = params[:citystatezip]

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
end
