class AddMissingColumnsToAssignments < ActiveRecord::Migration[8.0]
  COLUMNS = {
    show_template_review:                          { type: :boolean },
    show_teammate_review:                          { type: :boolean },
    is_pair_programming:                           { type: :boolean },
    has_mentors:                                   { type: :boolean },
    auto_assign_mentors:                           { type: :boolean },
    review_rubric_varies_by_round:                 { type: :boolean },
    review_rubric_varies_by_topic:                 { type: :boolean },
    review_rubric_varies_by_role:                  { type: :boolean },
    has_max_review_limit:                          { type: :boolean },
    is_review_done_by_teams:                       { type: :boolean },
    allow_self_reviews:                            { type: :boolean },
    is_review_anonymous:                           { type: :boolean },
    reviews_visible_to_other_reviewers:            { type: :boolean },
    set_allowed_number_of_reviews_per_reviewer:    { type: :integer },
    set_required_number_of_reviews_per_reviewer:   { type: :integer },
    maximum_number_of_reviews_per_submission:      { type: :integer },
    number_of_review_rounds:                       { type: :integer },
    review_strategy:                               { type: :string },
    title:                                         { type: :string },
    description:                                   { type: :text }
  }.freeze

  def change
    COLUMNS.each do |col, opts|
      add_column :assignments, col, opts[:type] unless column_exists?(:assignments, col)
    end
  end
end
