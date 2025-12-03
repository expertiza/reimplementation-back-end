class AddGradeAndCommentToResponseMaps < ActiveRecord::Migration[8.0]
  def change
    add_column :response_maps, :reviewer_grade, :integer
    add_column :response_maps, :reviewer_comment, :text
  end
end
