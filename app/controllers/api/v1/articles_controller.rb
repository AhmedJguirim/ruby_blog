module Api
  module V1
    class ArticlesController < BaseController
      before_action :set_article, only: [:show, :update, :destroy]
      before_action :ensure_owner, only: [:update, :destroy]
      #exception routes
      # skip_before_action :authenticate_user!, only: [:index, :show]
    
      def index
        @articles = Article.all.select(:id, :title, :created_at,:user_id,:summary)
        render json: @articles
      end

      def show
        render json: @article
      end

    def create
      puts params
      @user = User.find(@current_user_id)
      @article = Article.new(article_params)

      @article.user = @user

      if @article.save
        if params[:documents][:image1].present?
          @article.documents.create(file: params[:documents][:image1])  
        end
        if params[:documents][:image2].present?
          @article.documents.create(file: params[:documents][:image2])  
        end
        if params[:documents][:image3].present?
          @article.documents.create(file: params[:documents][:image3])  
        end
        render json: @article, status: :created
      else
        
        render json: @article.errors, status: :unprocessable_entity
      end
    end

    def update
      if @article.update(article_params)
        render json: @article
      else
        render json: @article.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      head :no_content
    end

    private
    def ensure_owner
    
      unless @article.user_id == @current_user_id
        render json: { error: 'You are not authorized to modify this article' }, status: :forbidden
      end
    end
    def set_article
      @article = Article.find(params[:id])
    end
  def article_params
    params.require(:article).permit(:title, :body, :summary,:image1,:image2,:image3)
  end
end
end
end