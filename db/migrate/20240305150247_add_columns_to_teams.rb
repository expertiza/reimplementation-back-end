class AddColumnsToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :name, :string
    add_column :teams, :parent_id, :integer
    add_column :teams, :type, :string
    add_column :teams, :comments_for_advertisement, :text
    add_column :teams, :advertise_for_partner, :boolean
    add_column :teams, :submitted_hyperlinks, :text
    add_column :teams, :directory_num, :integer
    add_column :teams, :grade_for_submission, :integer
    add_column :teams, :comment_for_submission, :text
    add_column :teams, :make_public, :boolean, default: false
    add_column :teams, :pair_programming_request, :integer
    remove_column :response_maps, :assignment_id, :integer
  end
end
