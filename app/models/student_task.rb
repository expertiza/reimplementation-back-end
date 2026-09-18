# frozen_string_literal: true

class StudentTask
  attr_accessor :assignment, :course, :current_stage, :participant, :stage_deadline, :topic, :permission_granted,
                :submission_updated, :started, :active_round

  # Initializes a new instance of the StudentTask class
  def initialize(args)
    @assignment = args[:assignment]
    @course = args[:course]
    @current_stage = args[:current_stage]
    @participant = args[:participant]
    @stage_deadline = args[:stage_deadline]
    @topic = args[:topic]
    @permission_granted = args[:permission_granted]
    @active_round = args[:active_round]
  end

  # create a new StudentTask instance from a Participant object.
  def self.create_from_participant(participant)
    assignment = participant.assignment
    next_due   = DueDate.next_due_date(assignment)
    # Fetch the real topic name from SignedUpTeam -> ProjectTopic
    team       = participant.team
    topic_name = SignedUpTeam.find_by(team_id: team&.id)&.project_topic&.topic_name
    current_stage = DueDate.current_stage_for(assignment)

    # Determine the active round from the current due date so that submission_updated? and
    # started? can scope their checks to the round the student is actually in,
    # rather than checking across all rounds (which causes round-1 work to make a
    # round-2 task appear started even when the student hasn't touched round 2 yet).
    active_round = next_due&.round

    task = new(
      assignment:         assignment.name,
      course:             assignment.course&.name || 'Unknown Course',
      topic:              topic_name,
      current_stage:      current_stage,
      stage_deadline:     parse_stage_deadline(next_due ? next_due.due_at.in_time_zone(participant.user.try(:timezonepref) || 'UTC') : 'Finished'),
      permission_granted: participant.permission_granted,
      participant:        participant,
      active_round:       active_round
    )
    task.submission_updated = task.submission_updated?
    task.started = task.started?
    task
  end


  # create an array of StudentTask instances for all participants linked to a user, sorted by deadline.
  # Three chained sort_by calls are not stable — each overwrites the previous ordering.
  # A single composite key [course, assignment, stage_deadline] gives deterministic,
  # consistent ordering in one pass.
  def self.tasks(user)
    # Preload the associations that create_from_participant dereferences for every
    # participant so that the list endpoint does not fire one query per participant
    # for each of these:
    #   participant.assignment         →  included via :assignment
    #   assignment.course              →  included via assignment: :course
    #   participant.user               →  included via :user  (for timezonepref)
    #
    # Remaining per-row queries that cannot be batched without schema changes:
    #   participant.team               →  resolved through TeamsParticipant (custom method,
    #                                     not a first-class has_one that AR can :include)
    #   SignedUpTeam / ProjectTopic    →  depends on team, same constraint
    #   DueDate.next_due_date          →  class method; hits AR cache after assignment preload
    #   reviews_written_in_current_stage →  scoped EXISTS query, one per participant
    AssignmentParticipant.where(user_id: user.id)
                         .includes(assignment: :course)
                         .includes(:user)
                         .map { |participant| StudentTask.create_from_participant(participant) }
                         .sort_by { |task| [task.course, task.assignment, task.stage_deadline] }
  end

  # Creates a StudentTask from a participant ID. Returns nil if the ID does not
  # match any AssignmentParticipant (other Participant subclasses are excluded to
  # avoid type-mismatch 500s). Preloads the same associations as tasks so
  # create_from_participant does not fire redundant queries per attribute access.
  def self.from_participant_id(id)
    participant = AssignmentParticipant
                    .where(id: id)
                    .includes(assignment: :course)
                    .includes(:user)
                    .first
    return nil unless participant

    create_from_participant(participant)
  end

  # Returns true if the student has started work in the current stage.
  def submission_updated?
    content_submitted_in_current_stage? ||
      reviews_written_in_current_stage?
  end

  # Returns true if the student has begun work in the current active stage.
  def started?
    in_work_stage? && submission_updated?
  end

  private

  def in_work_stage?
    [ExpertizaConstants::DeadlineTypes::NAMES[ExpertizaConstants::DeadlineTypes::SUBMISSION],
     ExpertizaConstants::DeadlineTypes::NAMES[ExpertizaConstants::DeadlineTypes::REVIEW]].include?(current_stage)
  end

  def content_submitted_in_current_stage?
    return false unless current_stage == 'submission'
    team = participant.team
    return false unless team
    # Submission stage has no round granularity — a hyperlink or file counts regardless.
    team.hyperlinks.present? || team.has_submissions?
  end

  def reviews_written_in_current_stage?
    return false unless current_stage == 'review'
    # Scope to the active round so that completing round-1 reviews does not make a
    # round-2 review task appear started when the student has not yet touched round 2.
    # When active_round is nil (single-round or indeterminate), fall back to checking
    # any submitted review so the predicate still works for non-multi-round assignments.
    scope = ReviewResponseMap.where(reviewer_id: participant.id)
                             .joins(:responses)
                             .where(responses: { is_submitted: true })
    if active_round.present?
      scope = scope.where(responses: { round: active_round })
    end
    scope.exists?
  end

  # Parses a date string or Time object into a Time instance.
  # Declared private via private_class_method because the `private` keyword only
  # restricts instance methods — class methods (self.*) remain public without it.
  def self.parse_stage_deadline(date_string)
    return date_string if date_string.is_a?(Time)
    Time.parse(date_string.to_s)
  rescue StandardError => e
    Rails.logger.error("Failed to parse stage deadline '#{date_string}': #{e.message}")
    Time.now + 1.year
  end
  private_class_method :parse_stage_deadline

end
