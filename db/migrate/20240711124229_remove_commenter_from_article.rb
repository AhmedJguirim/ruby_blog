class RemoveCommenterFromArticle < ActiveRecord::Migration[6.1]
  def change
    remove_column :articles, :commenter, :string
  end
end
