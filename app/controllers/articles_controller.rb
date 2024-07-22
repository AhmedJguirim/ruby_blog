class ArticlesController < ApplicationController
  before_action :set_article, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
  before_action :ensure_ownership, only: [:edit, :update, :destroy]

  def index
    @top_tags = Tag.joins(:articles)
    .select('tags.*, COUNT(articles.id) AS articles_count')
    .group('tags.id')
    .order('articles_count DESC')
    .limit(20)

    if params[:tag].present?
      @tag = Tag.find_by(name: params[:tag])
      @articles = @tag ? @tag.articles.select(:id, :title, :created_at,:user_id,:summary).order(created_at: :desc).page(params[:page]).per(12) : Article.none.page(params[:page])
    else
      @articles = Article.select(:id, :title, :created_at,:user_id,:summary).order(created_at: :desc).page(params[:page]).per(12)
    end


    @votes = current_user.votes.where(votable_type: 'Article') if user_signed_in?
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    tag_names = @article.tags.pluck(:name)
    #getting articles with same tags (at least 1) as the current article
    @articles = Article.joins(:tags)
    .where('tags.name IN (?)', tag_names)
    .where.not(id: @article.id)
    .select(:id, :title, :created_at)
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