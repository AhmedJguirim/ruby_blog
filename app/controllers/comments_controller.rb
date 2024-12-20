class CommentsController < ApplicationController
  before_action :set_article
  before_action :set_comment, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
  before_action :ensure_comment_owner, only: [:edit, :update, :destroy]
  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      if params[:comment][:image].present?
        @comment.create_document(file: params[:comment][:image])
      end
      redirect_to "#{article_path(@article)}#comment-section", notice: 'Comment was successfully created.'
    else
      redirect_to "#{article_path(@article)}#comment-section", alert: 'Error creating comment.'
    end
  end

  def edit
    
  end
  def update
    if @comment.update(comment_params)
      if params[:comment][:image].present?
        if @comment.document.present?
          @comment.document.update(file: params[:comment][:image])
        else
          @comment.create_document(file: params[:comment][:image])
        end
      else
        @comment.document.destroy
      end
      redirect_to @article, notice: 'Comment was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @comment.destroy
    redirect_to @article, notice: 'Comment was successfully deleted.'
  end

  def upvote
    vote(1)
  end

  def downvote
    vote(-1)
  end

  private

  def set_article
    @article = Article.find(params[:article_id])
  end

  def set_comment
    @comment = @article.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def ensure_comment_owner
    unless @comment.user == current_user
      redirect_to @article, alert: 'You are not authorized to perform this action.'
    end
  end

  def vote(value)
    @vote = @comment.votes.find_or_initialize_by(user: current_user)
    @vote.value = value
    if @vote.save
      redirect_back fallback_location: root_path, notice: 'Vote recorded successfully.'
    else
      redirect_back fallback_location: root_path, alert: 'Unable to record vote.'
    end
  end
end