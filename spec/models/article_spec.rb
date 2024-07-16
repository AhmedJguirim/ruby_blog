# spec/models/article_spec.rb
require 'rails_helper'

RSpec.describe Article, type: :model do
  describe "factories" do
    it "has a valid factory" do
      expect(build(:article)).to be_valid
    end

    it "has an invalid factory" do
      expect(build(:invalid_article)).to be_invalid
    end
    it "creates an article with comments" do
      article_with_comments = create(:article_with_comments)
      expect(article_with_comments.comments.count).to eq(3)
    end
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_length_of(:body).is_at_least(10) }
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_and_belong_to_many(:tags) }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe "with comments" do
    let(:article_with_comments) { create(:article_with_comments) }

    it "has the correct number of comments" do
      expect(article_with_comments.comments.count).to eq(3)
    end
  end

  describe "with tags" do
    let(:article_with_tags) { create(:article, :with_tags) }

    it "has the correct tags" do
      expect(article_with_tags.tags.pluck(:name)).to match_array(["Ruby", "Rails"])
    end
  end

  describe "body length" do
    context "with a standard body" do
      let(:article) { build(:article) }

      it "is valid" do
        expect(article).to be_valid
      end
    end

    context "with a long body" do
      let(:article) { build(:article, :with_long_body) }

      it "is valid" do
        expect(article).to be_valid
      end

      it "has a longer body" do
        expect(article.body.length).to be > 200
      end
    end
  end

  describe "bulk operations" do
    before do
      create_list(:article, 10)
    end

    it "correctly counts total articles" do
      expect(Article.count).to eq(10)
    end
  end
end