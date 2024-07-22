class CriticismsController < ApplicationController
  before_action :set_comment
  before_action :set_criticism, only: [:destroy]

  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:comment_id])
    @criticism = @comment.criticisms.build(criticism_params)
    @criticism.user = current_user
  
    if @criticism.save
      redirect_to "#{article_path(@article)}#comment-section", notice: 'Criticism was successfully created.'
    else
      redirect_to "#{article_path(@article)}#comment-section", alert: 'Error creating criticism.'
    end
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:comment_id])
    @criticism = @comment.criticisms.find(params[:id])
    
    if @criticism.user == current_user
      @criticism.destroy
      redirect_to @article, notice: 'Criticism was successfully removed.'
    else
      redirect_to @article, alert: 'You are not authorized to remove this criticism.'
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:comment_id])
  end

  def set_criticism
    @criticism = @comment.criticisms.find(params[:id])
  end

  def criticism_params
    params.require(:criticism).permit(:content)
  end
end