class StudentTasksController < ApplicationController

  # List retrieves all student tasks associated with the current logged-in user.
  def action_allowed?
    current_user_has_student_privileges?
  end
  def list
    # Retrieves all tasks that belong to the current user.
    @student_tasks = StudentTask.from_user(current_user)
    # Render the list of student tasks as JSON.
    render json: @student_tasks, status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  # The view function retrieves a student task based on a participant's ID.
  # It is meant to provide an endpoint where tasks can be queried based on participant ID.
  def view
    # Retrieves the student task where the participant's ID matches the provided parameter.
    # This function will be used for clicking on a specific student task to "view" its details.
    @student_task = StudentTask.from_participant_id(params[:id])
    # Render the found student task as JSON.
    render json: @student_task, status: :ok
  end
  


  def queue
    # Resolve participant + team + assignment context for current user.
    context = resolve_context_for_assignment(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    # Build ordered task list (quiz -> review sequencing preserved).
    tasks = build_tasks(context)
    
    # Ensure ResponseMap + Response records exist before returning.
    # Important: matches old lazy-creation behavior.
    ensure_response_objects!(tasks)

    # Return stable API contract (do not change keys).
    render json: serialize_tasks(tasks), status: :ok
  end

  def next_task
    # Resolve participant + team + assignment context for current user.
    context = resolve_context_for_assignment(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = build_tasks(context)
    ensure_response_objects!(tasks)

    # First incomplete task determines what user should do next.
    next_task = tasks.find { |task| !task.completed? }

    if next_task
      render json: next_task.to_h, status: :ok
    else
      # Explicit completion signal when queue is exhausted.
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  def start_task
    # Validate ResponseMap exists.
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    # Enforce ownership: only assigned reviewer can start task.
    participant = map.reviewer
    return render json: { error: "Unauthorized" }, status: :forbidden if participant.user_id != current_user.id

    # Rebuild queue context for this participant (must match queue endpoint behavior).
    context = resolve_context_for_participant(participant)
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless context

    tasks = build_tasks(context)
    
    # Find corresponding task in queue using map_id.
    current_task = find_task_for_map(tasks, map.id)
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    # Enforce strict ordering: cannot skip earlier tasks.
    unless prior_tasks_complete?(tasks, current_task)
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    # Ensure Response exists before user starts interacting.
    current_task.ensure_response!

    render json: {
      message: "Task started",
      task: current_task.to_h
    }, status: :ok
  end

  private

  def resolve_context_for_assignment(assignment_id)
    # Find participant for current user within assignment.
    participant = Participant.find_by(
      user_id: current_user.id,
      parent_id: assignment_id
    )
    return nil unless participant

    resolve_context_for_participant(participant)
  end

  def resolve_context_for_participant(participant)
    # Team context is required for duty + grouping.
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
    # Team-level duty overrides participant-level duty.
    Duty.find_by(id: team_participant.duty_id) || Duty.find_by(id: participant.duty_id)
  end

  def build_tasks(context)
    assignment = context[:assignment]
    participant = context[:participant]
    team_participant = context[:team_participant]
    duty = context[:duty]

    tasks = []

    # Fetch all review assignments for this user.
    review_maps = ReviewResponseMap.where(
      reviewer_id: participant.id,
      reviewed_object_id: assignment.id
    )

    quiz_questionnaire = assignment.quiz_questionnaire_for_review_flow

    # Important: allows quiz even if questionnaire removed later (existing maps).
    has_existing_quiz_maps = QuizResponseMap.where(
      reviewer_id: participant.id
    ).exists?

    # Preserve quiz-before-review ordering for every review map.
    if review_maps.any?
      review_maps.each do |review_map|
        # Quiz always comes BEFORE review for same review_map
        if duty_allows_quiz?(duty) && (quiz_questionnaire || has_existing_quiz_maps)
          tasks << QuizTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end

        # Review task tied directly to existing ReviewResponseMap.
        if duty_allows_review?(duty)
          tasks << ReviewTaskItem.new(
            assignment: assignment,
            team_participant: team_participant,
            review_map: review_map
          )
        end
      end

    # Edge case: If there are no review maps, expose only the standalone quiz task.
    elsif duty_allows_quiz?(duty) && quiz_questionnaire
      tasks << QuizTaskItem.new(
        assignment: assignment,
        team_participant: team_participant,
        review_map: nil
      )
    end

    tasks
  end

  def ensure_response_objects!(tasks)
    tasks.each do |task|
      # Lazy-create ResponseMap if needed (especially for quizzes).
      task.ensure_response_map!
      
      # Ensure Response row exists so UI can safely operate.
      task.ensure_response!
    end
  end

  def find_task_for_map(tasks, map_id)
    # Map lookup must be tolerant of nil maps and type differences.
    tasks.find do |task|
      map = task.response_map
      map && map.id.to_i == map_id.to_i
    end
  end

  def prior_tasks_complete?(tasks, current_task)
    # Enforces strict sequential workflow (quiz -> review).
    tasks.take_while { |task| task != current_task }.all?(&:completed?)
  end

  def serialize_tasks(tasks)
    # Keep response shape identical to pre-refactor API.
    tasks.map(&:to_h)
  end

  def duty_allows_review?(duty)
    return false if duty.nil?

    # Only these roles are allowed to perform reviews.
    duty.name.in?(%w[participant reader reviewer mentor])
  end

  def duty_allows_quiz?(duty)
    return false if duty.nil?

    # Quiz is slightly more permissive than review (no reviewer role required).
    duty.name.in?(%w[participant reader mentor])
  end

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

    def response_map
      raise NotImplementedError
    end

    def ensure_response_map!
      response_map
    end

    def ensure_response!
      map = response_map
      return if map.nil?

      Response.find_or_create_by!(
        map_id: map.id,
        round: 1
      ) do |response|
        response.is_submitted = false
      end
    end

    def completed?
      map = response_map
      return false if map.nil?

      Response.where(map_id: map.id, is_submitted: true).exists?
    end

    def to_h
      map = response_map
      {
        task_type: task_type,
        assignment_id: assignment.id,
        response_map_id: map&.id,
        response_map_type: map&.type,
        reviewee_id: map&.reviewee_id,
        team_participant_id: team_participant.id
      }
    end

    def to_task_hash
      to_h
    end
  end

  class QuizTaskItem < BaseTaskItem
    def task_type
      :quiz
    end

    def questionnaire
      assignment.quiz_questionnaire_for_review_flow
    end

    def response_map
      return @response_map if @response_map

      existing_map = QuizResponseMap.find_by(
        reviewer_id: team_participant.participant_id,
        reviewee_id: review_map&.reviewee_id || 0
      )
      return @response_map = existing_map if existing_map

      return nil if questionnaire.nil?

      attributes = {
        reviewer_id: team_participant.participant_id,
        reviewee_id: review_map&.reviewee_id || 0,
        reviewed_object_id: questionnaire.id,
        type: "QuizResponseMap"
      }

      @response_map = QuizResponseMap.new(attributes).tap { |map| map.save!(validate: false) }
    end
  end

  class ReviewTaskItem < BaseTaskItem
    def task_type
      :review
    end

    def response_map
      review_map
    end
  end
end
