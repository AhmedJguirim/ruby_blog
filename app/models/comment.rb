class Comment < ApplicationRecord

  belongs_to :article
  belongs_to :user
  has_many :criticisms
  has_many :votes, as: :votable, dependent: :destroy
  validates :body , presence: true

  def vote_total
    votes.sum(:value)
  end

end
