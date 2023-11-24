class AddScoreToResponseMap < ActiveRecord::Migration[7.0]
  def change
    add_column :response_maps, :score, :integer, default: 0
  end
end
