class AddAdvertisementFieldsToSignedUpTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :signed_up_teams, :comments_for_advertisement, :text
    add_column :signed_up_teams, :advertise_for_partner, :boolean
  end
end
