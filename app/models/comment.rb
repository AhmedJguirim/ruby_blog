class Comment < ApplicationRecord

  belongs_to :article
  belongs_to :user
  
  has_many :criticisms, dependent: :destroy
  has_many :votes, as: :votable, dependent: :destroy
  has_one :document, as: :documentable, dependent: :destroy

  validates :body , presence: true

  def vote_total
    votes.sum(:value)
  end

end
