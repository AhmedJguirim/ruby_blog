class VotesController < ApplicationController
    before_action :set_votable
  
    def create
      @vote = @votable.votes.new(user: current_user, value: params[:value])
  
      if @vote.save
        redirect_back fallback_location: root_path, notice: 'Vote recorded successfully.'
      else
        redirect_back fallback_location: root_path, alert: 'Unable to record vote.'
      end
    end
  
    def update
      @vote = @votable.votes.find_by(user: current_user)
  
      if @vote.update(value: params[:value])
        redirect_back fallback_location: root_path, notice: 'Vote updated successfully.'
      else
        redirect_back fallback_location: root_path, alert: 'Unable to update vote.'
      end
    end
  
    private
  
    def set_votable
      if params[:article_id]
        @votable = Article.find(params[:article_id])
      elsif params[:comment_id]
        @votable = Comment.find(params[:comment_id])
      else
        redirect_back fallback_location: root_path, alert: 'Invalid vote target.'
      end
    end
  end