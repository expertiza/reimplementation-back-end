class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, on_delete: :cascade do |t|
      t.string :name
      t.string :password_digest
      t.integer :role_id
      t.string :fullname
      t.string :email
      t.integer :parent_id
      t.string :mru_directory_path
      t.boolean :email_on_review
      t.boolean :email_on_submission
      t.boolean :email_on_review_of_review
      t.boolean :is_new_user
      t.boolean :master_permission_granted
      t.string :handle
      t.string :persistence_token
      t.string :timezonepref
      t.boolean :copy_of_emails
      t.integer :institution_id
      t.boolean :etc_icons_on_homepage
      t.integer :locale

      t.timestamps
    end
  end
end
