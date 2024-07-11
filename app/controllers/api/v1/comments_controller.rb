module Api
    module V1
class CommentsController < BaseController
    before_action :set_comment, only: [:show, :update, :destroy]
    #exception routes
    skip_before_action :authenticate_user!, only: [:index, :show]
    
    def index
      @comments = Comment.all
      render json: @comments
    end

    def show
      render json: @comment
    end

    def create
      @article = Article.find(params[:articleId])
      @comment = @article.comments.create(comment_params)

      if @comment.save
        render json: @comment, status: :created
      else
        render json: @comment.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @article = Article.find(params[:articleId])
      @comment = @article.comments.find(params[:id])
      @comment.destroy
      head :no_content
    end

    private

    def set_comment
      @comment = Comment.find(params[:id])
    end
  def comment_params
    params.require(:comment).permit(:commenter, :body, :status,:articleId)
  end
end
end
end