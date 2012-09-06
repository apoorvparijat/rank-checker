class ApplicationController < ActionController::Base
  protect_from_forgery

  
  private
    
    ##
    # returns the +current_user+'s object using the +user_id+ stored in +session[:user+id]+
    #
    # ==== Returns
    # +user+ object
    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
    
    
    
    def logged_in
      
      if(session[:user_id] != nil)
        return true
      end
      
      flash[:warning] = "Please login to continue"
      # session[:return_to] = request.request_uri
      redirect_to sessions_new_path
      return false
      
    end
  
  helper_method :current_user, :logged_in
  
end
