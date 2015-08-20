class OutputsController < ApplicationController

  def index
  	@outputs = Output.all
  	@start = -1
  	@end = 100000
    render 'index'
  end

  def dataforexport
  	@outputs = Output.all
  	@start = params[:start]
  	@end = params[:end]
    render 'index'
  end

  def dataforexport1
  	@outputs = Output.all
  	@start = params[:id]
  	@end = params[:id]
    render 'index'
  end

  def destroy
  	@outputs = Output.find_by(id: params[:id])
  	@outputs.destroy

  	redirect_to outputs_url, notice: "Record deleted."
  end
end
