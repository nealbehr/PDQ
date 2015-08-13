class ApprovedsController < ApplicationController

  def index
    @approveds = Approved.all
  end

  
end
