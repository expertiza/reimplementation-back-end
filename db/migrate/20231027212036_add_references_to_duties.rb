class AddReferencesToDuties < ActiveRecord::Migration[7.0]
  def change
    add_reference :duties, :assignment, null: false, foreign_key: true
  end
end
