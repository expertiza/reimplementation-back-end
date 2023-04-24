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
      t.boolean :email_on_review, default: false
      t.boolean :email_on_submission, default: false
      t.boolean :email_on_review_of_review, default: false
      t.boolean :is_new_user, default: true
      t.boolean :master_permission_granted, default: false
      t.string :handle
      t.string :persistence_token
      t.string :timezonepref
      t.boolean :copy_of_emails, default: false
      t.integer :institution_id
      t.boolean :etc_icons_on_homepage, default: false
      t.integer :locale

      t.timestamps
    end
  end
end
