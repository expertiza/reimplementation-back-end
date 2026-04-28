class StudentTasksController < ApplicationController

  def action_allowed?
    current_user_has_student_privileges?
  end

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
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue
    queue.ensure_response_objects!
    render json: queue.tasks.map(&:to_task_hash), status: :ok
  end

  def next_task
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue
    queue.ensure_response_objects!
    next_task = queue.tasks.find { |t| !t.completed? }
    if next_task
      render json: next_task.to_task_hash, status: :ok
    else
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  def start_task
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    participant = map.reviewer
    if participant.user_id != current_user.id
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    assignment = participant.assignment
    queue = TaskOrdering::TaskQueue.new(assignment, team_participant)
    tasks = queue.tasks
    current_task = tasks.find { |t| (rm = t.response_map) && rm.id == map.id }
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    previous_tasks = tasks.take_while { |t| t != current_task }
    if previous_tasks.any? { |t| !t.completed? }
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    current_task.ensure_response!
    render json: { message: "Task started", task: current_task.to_task_hash }, status: :ok
  end

  # ===========================================================================
  # Inner classes
  # ===========================================================================

  class BaseTaskItem
    attr_reader :assignment, :team_participant, :review_map

    def initialize(assignment:, team_participant:, review_map:)
      @assignment       = assignment
      @team_participant = team_participant
      @review_map       = review_map
    end

    def participant
      team_participant.participant
    end

    def ensure_response!
      map = response_map
      return nil unless map
      Response.find_or_create_by!(map_id: map.id, round: 1) do |r|
        r.is_submitted = false
      end
    end

    def completed?
      map = response_map
      return false unless map
      Response.exists?(map_id: map.id, round: 1, is_submitted: true)
    end

    def to_h
      map = response_map
      {
        task_type:           task_type,
        assignment_id:       assignment.id,
        response_map_id:     map&.id,
        response_map_type:   map&.class&.name,
        reviewee_id:         map&.reviewee_id,
        team_participant_id: team_participant.id
      }
    end

    # Alias so existing code using to_task_hash still works
    alias to_task_hash to_h
  end

  class ReviewTaskItem < BaseTaskItem
    def task_type = :review
    def response_map = review_map
  end

  class QuizTaskItem < BaseTaskItem
    def task_type = :quiz

    def response_map
      existing = QuizResponseMap.find_by(
        reviewer_id:        participant.id,
        reviewee_id:        review_map.reviewee_id,
        reviewed_object_id: assignment.id
      )
      return existing if existing

      questionnaire = assignment.quiz_questionnaire_for_review_flow
      return nil unless questionnaire

      map = QuizResponseMap.new(
        reviewer_id:        participant.id,
        reviewee_id:        review_map.reviewee_id,
        reviewed_object_id: assignment.id
      )
      map.save!(validate: false)
      map
    end
  end

  private

  def build_queue_for_user(assignment_id)
    participant = Participant.find_by(user_id: current_user.id, parent_id: assignment_id)
    return nil unless participant
    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant
    TaskOrdering::TaskQueue.new(participant.assignment, team_participant)
  end

  def build_tasks(context)
    assignment       = context[:assignment]
    participant      = context[:participant]
    team_participant = context[:team_participant]
    duty             = context[:duty]
    tasks            = []

    review_maps = ReviewResponseMap.where(reviewer_id: participant.id)

    review_maps.each do |rm|
      if duty.nil? || duty_allows_quiz?(duty)
        tasks << QuizTaskItem.new(assignment: assignment, team_participant: team_participant, review_map: rm) if assignment.quiz_questionnaire_for_review_flow
      end
      if duty.nil? || duty_allows_review?(duty)
        tasks << ReviewTaskItem.new(assignment: assignment, team_participant: team_participant, review_map: rm)
      end
    end

    if review_maps.empty? && (duty.nil? || duty_allows_quiz?(duty))
      if assignment.quiz_questionnaire_for_review_flow
        tasks << QuizTaskItem.new(assignment: assignment, team_participant: team_participant, review_map: ReviewResponseMap.new)
      end
    end

    tasks
  end

  def prior_tasks_complete?(tasks, current_task)
    tasks.take_while { |t| t != current_task }.all?(&:completed?)
  end

  def find_task_for_map(tasks, map_id)
    tasks.find { |t| t.response_map&.id.to_s == map_id.to_s }
  end

  def duty_allows_review?(duty)
    return false if duty.nil?
    %w[reviewer participant reader mentor].include?(duty.name)
  end

  def duty_allows_quiz?(duty)
    return false if duty.nil?
    %w[participant reader mentor].include?(duty.name)
  end

  def duty_allows_submit?(duty)
    return false if duty.nil?
    %w[submitter participant mentor].include?(duty.name)
  end
end