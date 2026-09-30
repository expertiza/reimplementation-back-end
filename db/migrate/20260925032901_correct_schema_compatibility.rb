class CorrectSchemaCompatibility < ActiveRecord::Migration[8.0]
  def up
    # Restore fields that are still required by the reimplementation.
    add_column :users, :mru_directory_path, :string unless column_exists?(:users, :mru_directory_path)

    add_column :users, :email_on_review, :boolean, default: false unless column_exists?(:users, :email_on_review)

    add_column :participants, :duty_id, :integer unless column_exists?(:participants, :duty_id)

    # "ratings" was a typo; the intended field name is "rating".
    if column_exists?(:bookmark_ratings, :ratings) &&
       !column_exists?(:bookmark_ratings, :rating)
      rename_column :bookmark_ratings, :ratings, :rating
    end
  end

  def down
    if column_exists?(:bookmark_ratings, :rating) &&
       !column_exists?(:bookmark_ratings, :ratings)
      rename_column :bookmark_ratings, :rating, :ratings
    end

    remove_column :participants, :duty_id if column_exists?(:participants, :duty_id)
    remove_column :users, :email_on_review if column_exists?(:users, :email_on_review)
    remove_column :users, :mru_directory_path if column_exists?(:users, :mru_directory_path)
  end
end
