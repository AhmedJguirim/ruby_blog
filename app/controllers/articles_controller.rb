class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :ensure_ownership, only: [:edit, :update, :destroy]

  def index
    @articles = Article.all.order(created_at: :desc)
    @votes = Vote.where(user: current_user , votable_type: "Article")

    return @articles, @votes
  end

  def show
    tag_names = @article.tags.pluck(:name)
    #getting articles with same tags (at least 1) as the current article
    @articles = Article.joins(:tags)
    .where('tags.name IN (?)', tag_names)
    .where.not(id: @article.id)
    .group('articles.id')
    .having('COUNT(DISTINCT tags.id) >= 1')
    .distinct
    .order('RANDOM()')
    .limit(5)
    return @articles, @article
  end

  def new
    @article = current_user.articles.build
  end

  def create
    @article = current_user.articles.build(article_params)

    if @article.save
      if params[:article][:images].present?
        params[:article][:images].first(3).each do |image|
          @article.documents.create(file: image)
        end
      end
      redirect_to @article, notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    @article.assign_attributes(article_params)
    
    if params[:article][:images].present?
      remaining_slots = 3 - @article.documents.count
      new_images = params[:article][:images].first(remaining_slots)
      
      new_images.each do |image|
        @article.documents.build(file: image)
      end
    end
  
    if @article.save
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