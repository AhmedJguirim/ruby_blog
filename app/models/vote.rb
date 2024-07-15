class Vote < ApplicationRecord
  belongs_to :user
  #https://guides.rubyonrails.org/association_basics.html#polymorphic-associations
  belongs_to :votable, polymorphic: true
end
