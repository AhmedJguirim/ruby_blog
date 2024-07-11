module Api
    module V1
      class SessionsController < BaseController
        skip_before_action :authenticate_user!, only: [:create]
  
        def create
            user = User.find_by(email: params[:email])
            if user && user.valid_password?(params[:password])
              jwt_secret = Rails.application.credentials.dig(:jwt, :secret_key)
              if jwt_secret.nil?
                render json: { error: 'JWT secret key is not set' }, status: :internal_server_error
              else
                token = JWT.encode({email: user.email, id: user.id, exp: 24.hours.from_now.to_i }, jwt_secret)
                render json: { token: token }
              end
            else
              render json: { error: 'Invalid email or password' }, status: :unauthorized
            end
          end
  
        def destroy
          jwt_denylist = JwtDenylist.create(jti: request.headers['Authorization'].split(' ').last, expired_at: Time.now)
          if jwt_denylist.persisted?
            render json: { message: 'Logged out successfully' }
          else
            render json: { error: 'Failed to logout' }, status: :unprocessable_entity
          end
        end
      end
    end
  end