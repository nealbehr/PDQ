class DensitiesController < ApplicationController



  def index
    @densities = Density.all
  end

  def show
    @density = Density.find_by(id: params[:id])
  end

  def new
  end

  def create
    @density = Density.new
    @density.zipcode = params[:zipcode]
    @density.densityofzip = params[:densityofzip]

    if @density.save
      redirect_to densities_url, notice: "Density created successfully."
    else
      render 'new'
    end
  end

  def edit
    @density = Density.find_by(id: params[:id])
  end

  def update
    @density = Density.find_by(id: params[:id])
    @density.zipcode = params[:zipcode]
    @density.densityofzip = params[:densityofzip]

    if @density.save
      redirect_to densities_url, notice: "Density updated successfully."
    else
      render 'edit'
    end
  end

  def destroy
    @density = Density.find_by(id: params[:id])
    @density.destroy

    redirect_to densities_url, notice: "Density deleted."
  end
end
