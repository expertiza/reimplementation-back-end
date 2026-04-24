# frozen_string_literal: true

class StudentTask
  attr_accessor :assignment, :assignment_id, :current_stage, :participant,
                :stage_deadline, :topic, :permission_granted,
                :require_quiz, :quiz_taken, :has_quiz_questionnaire, :quiz_questionnaire_id

  # Initializes a new instance of the StudentTask class
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

  # Creates a new StudentTask instance from a Participant object.
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

  # Creates an array of StudentTask instances for all participants linked to a user, sorted by deadline.
  def self.from_user(user)
    Participant.where(user_id: user.id)
               .filter_map { |participant| create_from_participant(participant) }
               .sort_by(&:stage_deadline)
  end

  # Creates a StudentTask instance from a participant of the provided id.
  def self.from_participant_id(id)
    create_from_participant(Participant.find_by(id: id))
  end

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

  # Parses a date string to a Time object; falls back to one year from now on failure.
  def self.parse_stage_deadline(date_string)
    Time.parse(date_string)
  rescue StandardError
    Time.now + 1.year
  end
end
