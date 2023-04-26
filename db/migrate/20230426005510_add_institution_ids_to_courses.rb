class AddInstitutionIdsToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :institutions_id, :integer
  end
end
