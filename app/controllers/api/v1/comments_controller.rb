module Api
    module V1
class CommentsController < BaseController
    before_action :set_comment, only: [:show, :update, :destroy]
    before_action :ensure_owner, only: [:update, :destroy]
    #exception routes
    # skip_before_action :authenticate_user!, only: [:index, :show]
    
    def index
      @comments = Comment.all
      render json: @comments
    end

    def getByArticle
      @comments = Comment.where(article_id: params['article'])
      render json: @comments
    end

    def show
      render json: @comment
    end

    def create
      @article = Article.find(params[:articleId])
      @comment = @article.comments.create(comment_params)
      @comment.user_id = @current_user_id
      if @comment.save
        render json: @comment, status: :created
      else
        render json: @comment.errors, status: :unprocessable_entity
      end
    end

    def update
      if @comment.update(comment_params)
        render json: @comment
      else
        render json: @comment.errors, status: :unprocessable_entity
      end
    end

    def destroy

      @comment = Comment.find(params[:id])
      @comment.destroy
      head :no_content
    end

    private
    def ensure_owner
      unless @comment.user_id == @current_user_id
        render json: { error: 'You are not authorized to modify this comment' }, status: :forbidden
      end
    end
    def set_comment
      @comment = Comment.find(params[:id])
    end
  def comment_params
    params.require(:comment).permit(:body, :status,:articleId)
  end
end
end
end