class AddTypeToResponseMaps < ActiveRecord::Migration[8.0]
  def change
    add_column :response_maps, :type, :string
  end
end
