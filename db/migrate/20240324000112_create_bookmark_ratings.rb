class CreateBookmarkRatings < ActiveRecord::Migration[7.0]
  def up
    create_table "bookmark_ratings" do |t|
      t.integer "bookmark_id"
      t.integer "user_id"
      t.integer "rating"
      t.timestamps
    end
  end
  def down
    drop_table "bookmark_ratings"
  end
end
