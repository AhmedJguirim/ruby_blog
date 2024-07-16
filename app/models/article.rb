class Article < ApplicationRecord
  
    has_many :comments, dependent: :destroy
    has_many :elaboration_requests
    has_many :votes, as: :votable
    belongs_to :user
    has_and_belongs_to_many :tags
    
    validates :title, presence: true
    validates :body, presence: true, length: { minimum: 10 }
    validates :summary, presence: true

    after_save :process_tags
    private 

    def process_tags
      # Extract tags from the body
      extracted_tags = body.scan(/#(\w+)/).flatten.uniq
  
      # Create or find tags and associate them with the article
      extracted_tags.each do |tag_name|
        tag = Tag.find_or_create_by(name: tag_name.downcase)
        self.tags << tag unless self.tags.include?(tag)
      end
  
      # Remove any tags that are no longer in the body
      self.tags.each do |tag|
        self.tags.delete(tag) unless extracted_tags.include?(tag.name)
      end
    end
  end
  