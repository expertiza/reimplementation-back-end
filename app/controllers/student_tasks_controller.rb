class StudentTasksController < ApplicationController

  # ---------------------------------------------------------------------------
  # Inner Classes
  # ---------------------------------------------------------------------------

  class BaseTaskItem
    attr_reader :assignment, :team_participant, :review_map

    def initialize(assignment:, team_participant:, review_map: nil)
      @assignment = assignment
      @team_participant = team_participant
      @review_map = review_map
    end

    def participant
      team_participant.participant
    end

    def task_type
      raise NotImplementedError
    end

    def response_map
      raise NotImplementedError
    end

    def completed?
      return false unless response_map
      Response.where(map_id: response_map.id, is_submitted: true).exists?
    end

    def ensure_response!
      return nil unless response_map
      Response.find_or_create_by(map_id: response_map.id, round: 1) do |r|
        r.is_submitted = false
      end
    end

    def to_h
      map = response_map
      {
        task_type: task_type,
        assignment_id: assignment.id,
        response_map_id: map&.id,
        response_map_type: map&.class&.name,
        reviewee_id: map&.reviewee_id,
        team_participant_id: team_participant.id
      }
    end

    # Keep backward compat with old to_task_hash callers
    alias to_task_hash to_h
  end

  class ReviewTaskItem < BaseTaskItem
    def task_type
      :review
    end

    def response_map
      @review_map
    end
  end

  class QuizTaskItem < BaseTaskItem
    def task_type
      :quiz
    end

    def response_map
      @cached_quiz_map ||= resolve_quiz_map
    end

    private

    def resolve_quiz_map
      reviewee_id = @review_map&.reviewee_id || 0

      # Return existing map if present
      existing = QuizResponseMap.find_by(
        reviewer_id: participant.id,
        reviewee_id: reviewee_id
      )
      return existing if existing

      # Create new map if questionnaire exists
      questionnaire = assignment.quiz_questionnaire_for_review_flow
      return nil unless questionnaire

      map = QuizResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: reviewee_id,
        reviewed_object_id: assignment.id
      )
      map.save!(validate: false)
      map
    end
  end

  # ---------------------------------------------------------------------------
  # Authorization
  # ---------------------------------------------------------------------------

  def action_allowed?
    current_user_has_student_privileges?
  end

  # ---------------------------------------------------------------------------
  # Actions
  # ---------------------------------------------------------------------------

  def list
    @student_tasks = StudentTask.from_user(current_user)
    render json: @student_tasks, status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    @student_task = StudentTask.from_participant_id(params[:id])
    render json: @student_task, status: :ok
  end

  def queue
    context = resolve_context_for_assignment(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = build_tasks(context)
    ensure_response_objects!(tasks)

    render json: serialize_tasks(tasks), status: :ok
  end

  def next_task
    context = resolve_context_for_assignment(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = build_tasks(context)
    ensure_response_objects!(tasks)

    next_incomplete = tasks.find { |t| !t.completed? }

    if next_incomplete
      render json: next_incomplete.to_task_hash, status: :ok
    else
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  def start_task
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    participant = map.reviewer
    unless participant.user_id == current_user.id
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    context = resolve_context_for_participant(participant)
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = build_tasks(context)
    current_task = find_task_for_map(tasks, map.id)
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    if !prior_tasks_complete?(tasks, current_task)
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    current_task.ensure_response!

    render json: { message: "Task started", task: current_task.to_task_hash }, status: :ok
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  private

  def resolve_context_for_assignment(assignment_id)
    participant = Participant.find_by(user_id: current_user.id, parent_id: assignment_id)
    return nil unless participant

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant

    {
      participant: participant,
      team_participant: team_participant,
      assignment: participant.assignment,
      duty: resolve_duty(team_participant, participant)
    }
  end

  def resolve_context_for_participant(participant)
    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant

    {
      participant: participant,
      team_participant: team_participant,
      assignment: participant.assignment,
      duty: resolve_duty(team_participant, participant)
    }
  end

  def resolve_duty(team_participant, participant)
    Duty.find_by(id: team_participant.duty_id) ||
      Duty.find_by(id: participant.duty_id)
  end

  def build_tasks(context)
    assignment     = context[:assignment]
    participant    = context[:participant]
    team_participant = context[:team_participant]
    duty           = context[:duty]

    review_maps = ReviewResponseMap.where(
      reviewer_id: participant.id,
      reviewed_object_id: assignment.id
    )

    quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow
    has_existing_quiz_maps = QuizResponseMap.where(reviewer_id: participant.id).exists?

    tasks = []

    if review_maps.any?
      review_maps.each do |review_map|
        if duty_allows_quiz?(duty) && (quiz_questionnaire || has_existing_quiz_maps)
          tasks << QuizTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end
        if duty_allows_review?(duty)
          tasks << ReviewTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end
      end
    else
      if duty_allows_quiz?(duty) && quiz_questionnaire
        tasks << QuizTaskItem.new(
          assignment: assignment,
          team_participant: team_participant,
          review_map: nil
        )
      end
    end

    tasks
  end

  def duty_allows_review?(duty)
    return true if duty.nil?
    %w[participant reader reviewer mentor].include?(duty.name)
  end

  def duty_allows_quiz?(duty)
    return true if duty.nil?
    %w[participant reader mentor].include?(duty.name)
  end

  def ensure_response_objects!(tasks)
    tasks.each do |task|
      task.ensure_response!
    end
  end

  def find_task_for_map(tasks, map_id)
    tasks.find { |t| t.response_map&.id.to_i == map_id.to_i }
  end

  def prior_tasks_complete?(tasks, target_task)
    tasks.take_while { |t| t != target_task }.all?(&:completed?)
  end

  def serialize_tasks(tasks)
    tasks.map(&:to_task_hash)
  end
end