class AddTeamToReviewMappings < ActiveRecord::Migration[7.1]
    def change
        # If this app doesn't have review_mappings yet, just skip.
        return unless table_exists?(:review_mappings)

        # Only add the column if it's missing.
        unless column_exists?(:review_mappings, :team_id)
            add_reference :review_mappings, :team, foreign_key: true, null: true
            add_index     :review_mappings, :team_id
        end
    end
end
