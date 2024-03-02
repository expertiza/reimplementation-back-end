class AddAssigmentToResponseMap < ActiveRecord::Migration[7.0]
  def change
    add_column :response_maps, :assignment_id, :integer
  end
end
