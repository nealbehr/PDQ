class OutputsController < ApplicationController

  require 'uri'

  def index
  	@outputs = Output.all
  	@start = -1
  	@end = 100000
    @forexport = false
    render 'index'
  end

  def datarun
    @outputs = Output.where(runid: params[:rangeID])
    @start = 0
    @end = 1000000
    @forexport = true
    render 'index'
  end


  def datarange
  	@outputs = Output.all
  	@start = params[:start]
  	@end = params[:end]
    @forexport = true
    render 'index'
  end

  def data
  	@outputs = Output.all
  	@start = params[:id]
  	@end = params[:id]
    @forexport = true
    render 'index'
  end

  def destroy
  	@outputs = Output.find_by(id: params[:id])
  	@outputs.destroy

  	redirect_to outputs_url, notice: "Record deleted."
  end

  def destroyrange
    for worker in params[:start]..params[:end]
      @outputs = Output.find_by(id: worker)
      next if @outputs == nil
      @outputs.destroy
    end
    redirect_to outputs_url, notice: "Records deleted."
  end

  def destroyrun
    @outputs = Output.all
    @outputs.each do |worker|
      puts params[:rangeID]
      puts worker.runid
      puts worker.runid == params[:rangeID]
      if worker.runid == params[:rangeID]
        worker.destroy
      end
    end
    redirect_to outputs_url, notice: "Records deleted."
  end

end
