class AddMissingReponseMapFields < ActiveRecord::Migration[7.0]
  def change
    add_column :response_maps, :type, :string
    add_column :response_maps, :calibrate_to, :integer
  end
end
