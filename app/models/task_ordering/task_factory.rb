# frozen_string_literal: true
module TaskOrdering
  class TaskFactory
    def self.build(assignment:, team_participant:)
      tasks = []
      participant = team_participant.participant
      duty = Duty.find_by(id: team_participant.duty_id) || Duty.find_by(id: participant.duty_id)

      review_maps = ReviewResponseMap.where(
        reviewer_id: team_participant.participant_id,
        reviewed_object_id: assignment.id
      )

      quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow

      # Check if any QuizResponseMaps exist for this participant
      has_existing_quiz_maps = QuizResponseMap.where(
        reviewer_id: team_participant.participant_id
      ).exists?

      if review_maps.any?
        review_maps.each do |review_map|
          # Add QuizTask if duty allows quizzes AND (questionnaire exists OR quiz maps already exist)
          if (duty.nil? || allows_quiz?(duty)) && (quiz_questionnaire || has_existing_quiz_maps)
            tasks << QuizTask.new(
              assignment: assignment,
              team_participant: team_participant,
              review_map: review_map
            )
          end

          if duty.nil? || allows_review?(duty)
            tasks << ReviewTask.new(
              assignment: assignment,
              team_participant: team_participant,
              review_map: review_map
            )
          end
        end
      elsif allows_quiz?(duty) && quiz_questionnaire
        tasks << QuizTask.new(
          assignment: assignment,
          team_participant: team_participant,
          review_map: nil
        )
      end

      tasks
    end

    def self.allows_review?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant reader reviewer mentor])
    end

    def self.allows_quiz?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant reader mentor])
    end

    def self.allows_submit?(duty)
      return false if duty.nil?
      duty.name.in?(%w[participant submitter mentor])
    end
  end
end