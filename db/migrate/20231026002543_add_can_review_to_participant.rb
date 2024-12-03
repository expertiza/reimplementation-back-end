class AddCanReviewToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :can_review, :boolean, :default => true
  end
end