class ProfilesController < ApplicationController
  def show
    @user = User.find(params[:id])
    @theories = @user.articles.order(created_at: :desc).page(params[:page]).per(12)
    @total_votes = @user.articles.sum { |article| article.votes.sum(:value) }
    @total_comments = @user.articles.sum { |article| article.comments.count }
    @votes = current_user.votes.where(votable_type: 'Article')
  end
end
