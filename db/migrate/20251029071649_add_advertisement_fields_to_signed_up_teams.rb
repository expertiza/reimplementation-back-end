class AddAdvertisementFieldsToSignedUpTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :signed_up_teams, :comments_for_advertisement, :text unless column_exists?(:signed_up_teams, :comments_for_advertisement)
    add_column :signed_up_teams, :advertise_for_partner, :boolean unless column_exists?(:signed_up_teams, :advertise_for_partner)
  end
end