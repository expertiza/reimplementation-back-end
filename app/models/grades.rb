# frozen_string_literal: true

class Grades
  COLUMN_NAMES = %w[
    assignment_id
    assignment_name
    team_id
    team_name
    participant_id
    participant_name
    participant_email
    submission_grade
    review_grade
    teammate_review_grade
    author_feedback_grade
  ].freeze

  Row = Struct.new(*COLUMN_NAMES.map(&:to_sym), keyword_init: true)

  extend ImportableExportableHelper

  export_submodels false

  mandatory_fields :assignment_name, :team_name, :participant_name
  # hidden_fields :id, :created_at, :updated_at
  filter -> { aggregate_grades }

  # Spoof a table-backed model so ImportableExportableHelper can treat
  # Grades like a normal exportable class.
  def self.column_names
    COLUMN_NAMES
  end

  def self.aggregate_grades
    AssignmentParticipant.includes(:user).map do |participant|
      assignment = participant.assignment
      team = participant.team
      next if assignment.nil? || team.nil?

      teammate_ids = team.participants.where.not(id: participant.id).pluck(:id)

      reviews_of_me_maps = TeammateReviewResponseMap.where(
        reviewed_object_id: assignment.id,
        reviewee_id: participant.id,
        reviewer_id: teammate_ids
      ).to_a

      reviews_by_me_maps = TeammateReviewResponseMap.where(
        reviewed_object_id: assignment.id,
        reviewer_id: participant.id
      ).to_a

      my_reviews_of_other_teams_maps = ReviewResponseMap.where(
        reviewed_object_id: assignment.id,
        reviewer_id: participant.id
      )

      feedback_from_my_reviewees_maps = my_reviews_of_other_teams_maps.filter_map do |map|
        FeedbackResponseMap.find_by(reviewed_object_id: map.id, reviewee_id: participant.id)
      end

      Row.new(
        assignment_id: assignment.id,
        assignment_name: assignment.name,
        team_id: team.id,
        team_name: team.name,
        participant_id: participant.id,
        participant_name: participant.user_name,
        participant_email: participant.user&.email,
        submission_grade: team.grade_for_submission,
        review_grade: team.aggregate_review_grade,
        teammate_review_grade: participant.aggregate_teammate_review_grade(reviews_of_me_maps),
        author_feedback_grade: participant.aggregate_teammate_review_grade(feedback_from_my_reviewees_maps)
      )
    end.compact
  end
end
