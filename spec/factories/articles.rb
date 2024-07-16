# spec/factories/articles.rb
FactoryBot.define do
    factory :article do
        sequence(:title) { |n| "Article Title #{n}" }
        body { "This is the body of the article. It needs to be at least 10 characters long." }
        summary { "A brief summary of the article." }
        association :user
        
        factory :article_with_comments do
          after(:create) do |article|
            create_list(:comment, 3, article: article)
          end
        end

        trait :with_long_body do
          body { "This is a much longer body of the article. It goes into great detail about the subject matter and provides a comprehensive overview of the topic at hand. This body is intentionally long to test any potential issues with lengthy content." }
        end
        trait :with_tags do
          after(:create) do |article|
            article.tags << create(:tag, name: "Ruby")
            article.tags << create(:tag, name: "Rails")
          end
        end
        factory :invalid_article do
            title { nil }  # Invalid because title is required
          end
      
    end

factory :user do
  sequence(:username) { |n| "user#{n}" }
  sequence(:email) { |n| "user#{n}@example.com" }
  password { "password123" }
end

factory :tag do
  sequence(:name) { |n| "Tag#{n}" }
end


end