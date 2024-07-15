class CreateElaborationRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :elaboration_requests do |t|
      t.text :content
      t.text :intent
      t.string :status
      t.text :response
      t.references :user, null: false, foreign_key: true
      t.references :article, null: false, foreign_key: true

      t.timestamps
    end
  end
end
