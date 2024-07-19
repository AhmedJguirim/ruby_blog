class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :authenticate_user!
    before_action :redirect_unless_auth_path

    protected
  
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:account_update, keys: [:username])
    end

    private

  def redirect_unless_auth_path
    unless user_signed_in? || auth_path?
      redirect_to new_user_session_path, alert: "Please sign in to access this page."
    end
  end

  def auth_path?
    
    params[:controller] == 'devise/sessions' || 
    params[:controller] == 'users/registrations' || 
    params[:controller] == 'users/passwords'
  end
end
