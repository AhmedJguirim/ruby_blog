module Api
    module V1
class CriticismsController < BaseController
    before_action :set_criticism, only: [:destroy]
    before_action :ensure_owner, only: [:destroy]
    #exception routes
    # skip_before_action :authenticate_user!, only: [:index, :show]
    
    def index
      @criticisms = Criticism.where(comment_id: params['comment'])
      render json: @criticisms
    end

    def create
      @user = User.find(@current_user_id)
      @criticism = @user.criticisms.build(criticism_params)
      if @criticism.save
        render json: @criticism, status: :created
      else
        render json: @criticism.errors, status: :unprocessable_entity
      end
    end

    def destroy   
      @criticism.destroy
      head :no_content
    end

    private
    def set_criticism
      @criticism = Criticism.find(params[:id])
    end
    def ensure_owner
      unless @criticism.user_id == @current_user_id
        render json: { error: 'You are not authorized to modify this criticism' }, status: :forbidden
      end
    end
  def criticism_params
    params.permit(:content, :comment_id, :criticism)
  end
end
end
end