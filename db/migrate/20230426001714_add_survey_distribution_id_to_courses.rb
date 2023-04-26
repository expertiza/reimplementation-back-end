class AddSurveyDistributionIdToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :survey_distribution_id, :string
  end
end
