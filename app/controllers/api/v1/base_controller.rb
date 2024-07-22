# app/controllers/api/v1/base_controller.rb
# a base controller that the Restapi side of the app that provides jwt api protection methods
module Api
    module V1
      class BaseController < ActionController::Base
        before_action :authenticate_user!
        protect_from_forgery with: :null_session
        respond_to :json
  
        private
  
        def authenticate_user!
          
          if request.headers['Authorization'].present?
            jwt_secret = Rails.application.credentials.dig(:jwt, :secret_key)
            jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, 
                                     jwt_secret).first
            @current_user_id = jwt_payload['id']
            @current_user_email = jwt_payload['email']
          else
            render json: { error: 'Authorization header missing' }, status: :unauthorized
          end
        rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
          render json: { error: 'Invalid or expired token' }, status: :unauthorized
        end
        
        # TODO: doesn't work in create function
        def current_user
          @current_user ||= User.find(@current_user_id)
        end

        def decode_auth_token
          jwt_secret = Rails.application.credentials.dig(:jwt, :secret_key)
          JWT.decode(request.headers['Authorization'].split(' ').last, jwt_secret).first
        end
      end
    end
  end