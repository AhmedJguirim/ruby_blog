class Criticism < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }
end
