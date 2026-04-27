# frozen_string_literal: true

# Represents a student's self-review session for a quiz questionnaire.
#
# A {QuizResponseMap} is distinguished from a regular {ReviewResponseMap} by
# having +reviewer_id == reviewee_id+ — both reference the same
# {AssignmentParticipant} record (the student who is taking the quiz).
# +reviewed_object_id+ points to the {Questionnaire} (quiz) rather than to
# the {Assignment}, following the original Expertiza convention.
#
# The +assignment+ association is optional because the quiz questionnaire is
# owned by a team rather than attached directly to an assignment, so no
# +assignment_id+ foreign key is stored on this record.
class QuizResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :quiz_questionnaire, foreign_key: 'reviewed_object_id', inverse_of: false
  # The assignment association is optional: quiz maps are keyed on a
  # questionnaire id, not an assignment id, so this FK may be absent.
  belongs_to :assignment, optional: true, inverse_of: false
  has_many :quiz_responses, foreign_key: :map_id, dependent: :destroy, inverse_of: false

  # Returns the {Questionnaire} associated with this map.
  # Delegates to the +quiz_questionnaire+ association so that the generic
  # response pipeline can call +map.questionnaire+ uniformly.
  #
  # @return [Questionnaire]
  def questionnaire
    quiz_questionnaire
  end

  # Returns all {QuizResponseMap} records where the given participant is the reviewer.
  #
  # @param participant_id [Integer] the {AssignmentParticipant} id of the student
  # @return [ActiveRecord::Relation<QuizResponseMap>]
  def self.mappings_for_reviewer(participant_id)
    QuizResponseMap.where(reviewer_id: participant_id)
  end

  # @return [String] human-readable title constant for this map type
  def get_title
    QUIZ_RESPONSE_MAP_TITLE
  end
end