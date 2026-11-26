class AddUniqueIndexToProjectTopicsIdentifier < ActiveRecord::Migration[8.0]
  def change
    # Backs the model's uniqueness: { scope: :assignment_id } validation with an actual
    # database constraint. The validation alone runs a SELECT before the INSERT, so two
    # concurrent creates can both pass it and both land. MySQL allows multiple NULLs in
    # a unique index, so topics with no identifier are unaffected.
    add_index :project_topics, %i[assignment_id topic_identifier],
              unique: true, name: 'idx_project_topics_assignment_identifier'
  end
end
