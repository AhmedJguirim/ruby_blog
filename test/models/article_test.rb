require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "article should be created" do
    article = Article.new
    article.body = "ezfiziugziguzoigz"
    article.title = "zguizughrzuihguzrehguierhu"
    article.status = "erugheiruhgueirhguieergoero"
    article.user_id = 1
    assert article.save
  end
  
end
