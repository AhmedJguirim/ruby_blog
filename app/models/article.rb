class Article < ApplicationRecord
    include Visible
  
    has_many :comments, dependent: :destroy
    belongs_to :user
    has_many :comments
    
    validates :title, presence: true
    validates :body, presence: true, length: { minimum: 10 }
  end
  