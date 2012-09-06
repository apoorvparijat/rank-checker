class SessionsController < ApplicationController
  
  before_filter :logged_in, :only => ['index']
  
  def show
  
  end
  
  def new
    if (current_user)
      redirect_url = request.env["HTTP_REFERER"] != nil ? request.env["HTTP_REFERER"] : ranks_path
      redirect_to redirect_url
    end
  end
  
  def create
    user = User.find_by_email(params[:email])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to ranks_path, :noitce => "Logged in!"
    else
      flash.now.alert = "Invalid email or password"
      redirect_to new_user_path
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to sessions_new_path
  end
  
end
