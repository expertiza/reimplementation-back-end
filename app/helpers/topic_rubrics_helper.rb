# frozen_string_literal: true

module TopicRubricsHelper
  # Assign a questionnaire to a specific topic
  def self.assign_rubric_to_topic(topic_id, questionnaire_id, assignment_id, round = nil)
    topic = SignUpTopic.find(topic_id)
    assignment = Assignment.find(assignment_id)
    questionnaire = Questionnaire.find(questionnaire_id)

    # Validate that the questionnaire belongs to this assignment
    unless assignment.questionnaires.include?(questionnaire)
      raise ArgumentError, 'Questionnaire must be associated with this assignment'
    end

    # Check if assignment_questionnaire already exists
    assignment_questionnaire = AssignmentQuestionnaire.find_or_initialize_by(
      assignment_id: assignment_id,
      questionnaire_id: questionnaire_id,
      topic_id: topic_id,
      used_in_round: round
    )

    assignment_questionnaire.save!
    assignment_questionnaire
  end

  # Remove rubric assignment from a topic
  def self.remove_rubric_from_topic(topic_id, assignment_id, round = nil)
    AssignmentQuestionnaire.where(
      assignment_id: assignment_id,
      topic_id: topic_id,
      used_in_round: round
    ).destroy_all
  end

  # Get the rubric for a topic (with fallback to default)
  def self.get_rubric_for_topic(topic_id, round = nil)
    topic = SignUpTopic.find(topic_id)
    topic.rubric_for_review(round)
  end
end