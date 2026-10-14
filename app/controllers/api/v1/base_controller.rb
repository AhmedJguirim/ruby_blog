module Api
    module V1
      class BaseController < ActionController::Base
        before_action :authenticate_user!
        protect_from_forgery with: :null_session
        respond_to :json

        private

        def authenticate_user!
          if request.headers['Authorization'].present?
            jwt_payload = decode_auth_token
            @current_user_id = jwt_payload['id']
            @current_user_email = jwt_payload['email']
          else
            render json: { error: 'Authorization header missing' }, status: :unauthorized
          end
        rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
          render json: { error: 'Invalid or expired token' }, status: :unauthorized
        end

        def current_user
          @current_user ||= User.find(@current_user_id)
        end

        def decode_auth_token
          token = request.headers['Authorization'].split(' ').last
          # a token that was logged out must stop working
          raise JWT::DecodeError, 'token revoked' if JwtDenylist.exists?(jti: token)

          JWT.decode(token, Rails.configuration.x.jwt_secret, true, algorithm: 'HS256').first
        end
      end
    end
  end
