class ArticlesController < ApplicationController

  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new
  end

  def create
    if !user_signed_in?
      flash[:notice] = "you need to sign in to create an article"
      redirect_to new_user_session_path  and return
    end
    @user = current_user
    @article = @user.articles.create(article_params)
    if @article.save
      redirect_to @article
    else
      render :new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])
    if @article.user_id!= current_user.id
      flash[:notice] = "this is not your article to alter"
      redirect_to @article  and return
    end
    if @article.update(article_params)
      redirect_to @article
    else
      render :edit
    end
  end


  def destroy
    @article = Article.find(params[:id])
    if @article.user_id!= current_user.id
      flash[:notice] = "this is not your article to alter"
      redirect_to @article  and return
    end
    @article.destroy

    redirect_to root_path
  end

  private
  def article_params
    params.require(:article).permit(:title, :body, :status)
  end

end
