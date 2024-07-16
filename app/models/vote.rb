class Vote < ApplicationRecord
  belongs_to :user
  #https://guides.rubyonrails.org/association_basics.html#polymorphic-associations
  belongs_to :votable, polymorphic: true

  validates :value, inclusion: { in: [-1, 1] }
  validates :user_id, uniqueness: { scope: [:votable_type, :votable_id] }
end
