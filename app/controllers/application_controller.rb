class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :redirect_unless_auth_path

    protected
  
    #allows username to be updated
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:account_update, keys: [:username])
    end

    private

    # redirects user to sign in page in case he's not authenticated
  def redirect_unless_auth_path
    unless user_signed_in? || auth_path?
      redirect_to new_user_session_path, alert: "Please sign in to access this page."
    end
  end

  #public paths
  def auth_path?
    params[:controller] == 'devise/sessions' || 
    params[:controller] == 'users/registrations'
  end
end
