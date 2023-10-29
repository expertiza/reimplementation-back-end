class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table "teams_assignments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.string "name"
      t.integer "parent_id"
      t.string "type"
      t.text "comments_for_advertisement"
      t.boolean "advertise_for_partner"
      t.text "submitted_hyperlinks"
      t.integer "directory_num"
      t.integer "grade_for_submission"
      t.text "comment_for_submission"
      t.integer "pair_programming_request", limit: 1
    end
  end
end
