class ApprovedsController < ApplicationController

  def index
    @approveds = Approved.all
  end

  def show
    @approved = Approved.find_by(id: params[:id])
  end

  def new
  end

  def create
    @approved = Approved.new
    @approved.zipcode = params[:zipcode]
    @approved.status = params[:status]

    if @approved.save
      redirect_to approveds_url, notice: "Approved created successfully."
    else
      render 'new'
    end
  end

  def edit
    @approved = Approved.find_by(id: params[:id])
  end

  def update
    @approved = Approved.find_by(id: params[:id])
    @approved.zipcode = params[:zipcode]
    @approved.status = params[:status]

    if @approved.save
      redirect_to approveds_url, notice: "Approved updated successfully."
    else
      render 'edit'
    end
  end

  def destroy
    @approved = Approved.find_by(id: params[:id])
    @approved.destroy

    redirect_to approveds_url, notice: "Approved deleted."
  end
end
