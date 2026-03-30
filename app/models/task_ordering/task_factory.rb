# frozen_string_literal: true

# Factory responsible for constructing ordered task objects
# for a participant based on their duty and assigned review maps.
# Tasks are created per review map when review mappings exist.
module TaskOrdering
  class TaskFactory
    def self.build(assignment:, team_participant:)
      tasks = []
      participant = team_participant.participant
      duty = Duty.find_by(id: team_participant.duty_id) || Duty.find_by(id: participant.duty_id)

      # Fetch all review mappings where this participant is the reviewer
      # for this assignment.
      review_maps = ReviewResponseMap.where(
        reviewer_id: team_participant.participant_id,
        reviewed_object_id: assignment.id
      )

      # Quiz questionnaire used in the review flow (if assignment has quizzes)
      quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow

      if review_maps.any?
        # For each review mapping, create tasks in strict order:
        # 1. QuizTask (if quizzes enabled for this duty)
        # 2. ReviewTask
        review_maps.each do |review_map|
          if allows_quiz?(duty) && quiz_questionnaire
            tasks << QuizTask.new(
              assignment: assignment,
              team_participant: team_participant,
              review_map: review_map
            )
          end
          if allows_review?(duty)
            tasks << ReviewTask.new(
              assignment: assignment,
              team_participant: team_participant,
              review_map: review_map
            )
          end
        end
      # Case where participant has quiz but no review mappings yet.
      elsif allows_quiz?(duty) && quiz_questionnaire
        tasks << QuizTask.new(
          assignment: assignment,
          team_participant: team_participant,
          review_map: nil
        )
      end

      tasks
    end

    # Determines whether a duty is allowed to perform reviews.
    def self.allows_review?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant reader reviewer mentor])
    end

    # Determines whether a duty must complete quizzes in the review flow.
    def self.allows_quiz?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant reader mentor])
    end

    # Determines whether a duty can submit assignment work.
    # Not currently used in task queue but included for completeness.
    def self.allows_submit?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant submitter mentor])
    end
  end
end
