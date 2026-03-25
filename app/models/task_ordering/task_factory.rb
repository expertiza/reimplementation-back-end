module TaskOrdering
  class TaskFactory
    def self.build(assignment:, team_participant:)
      tasks = []

      participant = team_participant.participant
      duty = Duty.find_by(id: team_participant.duty_id)

      # Fetch all review mappings assigned to this participant
      review_maps = ReviewResponseMap.where(
        reviewer_id: team_participant.participant_id,
        reviewed_object_id: assignment.id
      )

      quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow 

      # QUIZ TASKS (STRUCTURAL)
      # If duty allows quiz AND questionnaire exists -> create quiz tasks
      if allows_quiz?(duty) && quiz_questionnaire
        if review_maps.any?
          # Quiz tied to each review (review-flow quiz)
          review_maps.each do |review_map|
            tasks << QuizTask.new(
              assignment: assignment,
              participant: participant,
              review_map: review_map
            )
          end
        else
          # Reading quiz (no review mapping)
          tasks << QuizTask.new(
            assignment: assignment,
            participant: participant
          )
        end
      end

      # REVIEW TASKS (STRUCTURAL)
      if allows_review?(duty)
        review_maps.each do |review_map|
          tasks << ReviewTask.new(
            assignment: assignment,
            participant: participant,
            review_map: review_map
          )
        end
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