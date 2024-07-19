class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  has_many :articles
  has_many :comments
  has_many :criticisms
  has_many :votes
  has_many :elaboration_requests

  def total_votes_received
    articles.sum { |article| article.votes.sum(:value) }
  end

  def total_comments_received
    articles.sum { |article| article.comments.count }
  end
end