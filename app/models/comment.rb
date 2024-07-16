class Comment < ApplicationRecord

  belongs_to :article
  belongs_to :user
  has_many :criticisms
  has_many :votes, as: :votable

end
