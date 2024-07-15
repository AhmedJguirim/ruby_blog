class CreateCriticisms < ActiveRecord::Migration[6.1]
  def change
    create_table :criticisms do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.references :comment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
