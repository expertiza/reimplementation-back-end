
# Assigns a quiz to a participant for a specific assignment
#
# @param assignment_id [Integer] The ID of the assignment
# @param reviewer_id [Integer] The ID of the reviewer (user)
# @param questionnaire_id [Integer] The ID of the questionnaire
# @return [OpenStruct] An object containing:
#   - success [Boolean] Whether the assignment was successful
#   - quiz_response_map [QuizResponseMap] The created mapping if successful
#   - error [String] Error message if any
def self.assign_quiz(assignment_id:, reviewer_id:, questionnaire_id:)
  # Find the participant for this assignment
  participant = AssignmentParticipant.find_by(user_id: reviewer_id, parent_id: assignment_id)
  return OpenStruct.new(success: false, error: 'Participant not registered for this assignment') unless participant

  # Check if quiz already taken
  if exists?(reviewer_id: participant.id, reviewed_object_id: questionnaire_id)
    return OpenStruct.new(success: false, error: 'You have already taken this quiz')
  end

  # Find the questionnaire
  questionnaire = Questionnaire.find(questionnaire_id)
  
  # Create the quiz response mapping
  quiz_response_map = create!(
    reviewee_id: questionnaire.instructor_id,
    reviewer_id: participant.id,
    reviewed_object_id: questionnaire.id
  )

  OpenStruct.new(success: true, quiz_response_map: quiz_response_map)
rescue ActiveRecord::RecordNotFound => e
  OpenStruct.new(success: false, error: 'Questionnaire not found')
rescue ActiveRecord::RecordInvalid => e
  OpenStruct.new(success: false, error: e.message)
rescue StandardError => e
  OpenStruct.new(success: false, error: e.message)
end

# ... existing code ... 