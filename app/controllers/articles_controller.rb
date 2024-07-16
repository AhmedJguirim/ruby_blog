class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :ensure_ownership, only: [:edit, :update, :destroy]

  def index
    @articles = Article.all
  end

  def show
  end

  def new
    @article = current_user.articles.build
  end

  def create
    @article = current_user.articles.build(article_params)
    
    if @article.save
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @article.update(article_params)
      redirect_to @article, notice: 'Article was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @article.destroy
    redirect_to root_path, notice: 'Article was successfully destroyed.'
  end

  def upvote
    vote(1)
  end

  def downvote
    vote(-1)
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def ensure_ownership
    unless @article.user_id == current_user.id
      flash[:alert] = "This is not your article to alter."
      redirect_to @article
    end
  end

  def vote(value)
    @vote = @article.votes.find_or_initialize_by(user: current_user)
    @vote.value = value

    if @vote.save
      redirect_back fallback_location: root_path, notice: 'Vote recorded successfully.'
    else
      redirect_back fallback_location: root_path, alert: 'Unable to record vote.'
    end
  end

  def article_params
    params.require(:article).permit(:title, :body, :summary)
  end
end