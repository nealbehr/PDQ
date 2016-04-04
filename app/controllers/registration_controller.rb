class RegistrationController < ApplicationController

  def new
  end

  def create
    if current_user != nil && current_user.admin? == true    
      puts "We are about to create this user!"
      puts "New user: " + params[:email].to_s
      puts "Current User: " + current_user.to_s
      @user = User.new
      @user.email = params[:email]
      @user.password = params[:password]
      @user.password_confirmation = params[:password]

      if @user.save
        redirect_to addresses_url, notice: "User created successfully."
      else
        render 'blank'
      end
    else
      render 'blank'
    end
  end
  
  def show
    if current_user != nil && current_user.admin? == true   
      @users = User.all
      render 'show'
    else
      render 'blank'
    end
  end

  def destroy
    if current_user != nil && current_user.admin? == true   
      @user = User.find_by(id: params[:id])
      @user.destroy

      @users = User.all
      render 'show'
    else
      render 'blank'
    end
  end


end
