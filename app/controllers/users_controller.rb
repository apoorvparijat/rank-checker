class UsersController < ApplicationController
  def new
    @user = User.new
    respond_to do |format|
      format.html
    end
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to ranks_path
    else
      render "new"
    end
  end
end
