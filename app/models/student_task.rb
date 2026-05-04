# frozen_string_literal: true

# Plain Ruby object (not an ActiveRecord model) that aggregates assignment,
# stage, and quiz state for a single student participant.
#
# Each instance is built from an {AssignmentParticipant} and is serialised
# directly to the student tasks API response. The quiz-related fields
# (+require_quiz+, +quiz_taken+, +has_quiz_questionnaire+,
# +quiz_questionnaire_id+) were added to enable the frontend to gate the
# "Start Review" button behind a mandatory quiz.
class StudentTask
  attr_accessor :assignment, :assignment_id, :current_stage, :participant,
                :stage_deadline, :topic, :permission_granted,
                :require_quiz, :quiz_taken, :has_quiz_questionnaire, :quiz_questionnaire_id

  # Initialises a new StudentTask from an argument hash.
  #
  # @param args [Hash] keyword arguments
  # @option args [String] :assignment human-readable assignment name
  # @option args [Integer] :assignment_id numeric assignment ID
  # @option args [String] :current_stage the participant's current workflow stage
  # @option args [Participant] :participant the underlying {Participant} record
  # @option args [Time] :stage_deadline deadline for the current stage
  # @option args [Topic, nil] :topic the signup topic, if any
  # @option args [Boolean] :permission_granted whether publishing rights are granted
  # @option args [Boolean] :require_quiz whether the assignment mandates a quiz before reviewing
  # @option args [Boolean] :quiz_taken whether the student has already submitted the quiz
  # @option args [Boolean] :has_quiz_questionnaire whether a quiz questionnaire exists for the reviewee team
  # @option args [Integer, nil] :quiz_questionnaire_id ID of the quiz questionnaire, or nil
  def initialize(args)
    @assignment        = args[:assignment]
    @assignment_id     = args[:assignment_id]
    @current_stage     = args[:current_stage]
    @participant       = args[:participant]
    @stage_deadline    = args[:stage_deadline]
    @topic             = args[:topic]
    @permission_granted = args[:permission_granted]
    @require_quiz            = args[:require_quiz]
    @quiz_taken              = args[:quiz_taken]
    @has_quiz_questionnaire  = args[:has_quiz_questionnaire]
    @quiz_questionnaire_id   = args[:quiz_questionnaire_id]
  end

  # Builds a {StudentTask} from a {Participant} record.
  #
  # Resolves the reviewee team via the participant's {ReviewResponseMap} and
  # reads +quiz_questionnaire_id+ directly from the team record. A quiz is
  # considered "taken" when a submitted {Response} exists on the corresponding
  # {QuizResponseMap}.
  #
  # Returns +nil+ if the participant has no associated assignment.
  #
  # @param participant [Participant] the participant to build from
  # @return [StudentTask, nil]
  def self.create_from_participant(participant)
    asgn = participant.assignment
    return nil if asgn.nil?

    # E2619: look up the quiz questionnaire from the reviewee team's quiz_questionnaire_id.
    # Previously this used assignment_questionnaires (instructor-assigned quiz), but quiz creation
    # is now team-driven: each submitting team creates their own quiz from the AssignReviewer page,
    # and the quiz is linked to their team record rather than the assignment.
    # We find the response maps where this participant is the reviewer, get the reviewee team,
    # and read team.quiz_questionnaire_id.
    reviewee_team = ReviewResponseMap
                      .where(reviewer_id: participant.id)
                      .filter_map { |rm| Team.find_by(id: rm.reviewee_id) }
                      .first
    quiz_questionnaire_id = reviewee_team&.quiz_questionnaire_id
    has_quiz = quiz_questionnaire_id.present?

    # Quiz is "taken" only when the student has a submitted response on their QuizResponseMap
    quiz_taken = has_quiz &&
                 QuizResponseMap
                   .where(reviewer_id: participant.id, reviewed_object_id: quiz_questionnaire_id)
                   .joins("INNER JOIN responses ON responses.map_id = response_maps.id")
                   .where(responses: { is_submitted: true })
                   .exists?

    new(
      assignment:              asgn.name,
      assignment_id:           asgn.id,
      topic:                   participant.topic,
      current_stage:           participant.current_stage,
      stage_deadline:          parse_stage_deadline(participant.stage_deadline),
      permission_granted:      participant.permission_granted,
      participant:             participant,
      require_quiz:            asgn.require_quiz || false,
      quiz_taken:              quiz_taken,
      has_quiz_questionnaire:  has_quiz,
      quiz_questionnaire_id:   quiz_questionnaire_id
    )
  end

  # Returns all {StudentTask} objects for a user, sorted by +stage_deadline+.
  #
  # Participants with no assignment (returning +nil+ from
  # {create_from_participant}) are silently dropped via +filter_map+.
  #
  # @param user [User] the student user
  # @return [Array<StudentTask>]
  def self.from_user(user)
    Participant.where(user_id: user.id)
               .filter_map { |participant| create_from_participant(participant) }
               .sort_by(&:stage_deadline)
  end

  # Builds a {StudentTask} from a participant looked up by its primary key.
  #
  # @param id [Integer] the {Participant} ID
  # @return [StudentTask, nil]
  def self.from_participant_id(id)
    create_from_participant(Participant.find_by(id: id))
  end

  # Serialises the task to a plain Hash for JSON API responses.
  #
  # All quiz-related fields are included so the frontend can determine
  # whether to show the quiz gate without additional requests.
  #
  # @return [Hash]
  def as_json(_options = {})
    {
      assignment:         @assignment,
      assignment_id:      @assignment_id,
      topic:              @topic,
      current_stage:      @current_stage,
      stage_deadline:     @stage_deadline,
      permission_granted: @permission_granted,
      require_quiz:            @require_quiz,
      quiz_taken:              @quiz_taken,
      has_quiz_questionnaire:  @has_quiz_questionnaire,
      quiz_questionnaire_id:   @quiz_questionnaire_id,
      participant_id:          @participant&.id
    }
  end

  private

  # Parses a deadline string into a {Time} object.
  #
  # Falls back to one year from now when the string cannot be parsed so that
  # sorting tasks never raises an error on malformed deadline data.
  #
  # @param date_string [String, nil] the deadline string to parse
  # @return [Time]
  def self.parse_stage_deadline(date_string)
    Time.parse(date_string)
  rescue StandardError
    Time.now + 1.year
  end
end
