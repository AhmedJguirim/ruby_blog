
FactoryBot.define do
    factory :comment do
      body { "This is a comment." }
      association :user
      association :article
    end
  end