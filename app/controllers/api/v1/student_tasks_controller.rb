class Api::V1::StudentTasksController < ApplicationController
  before_action :set_student_task, only: %i[show update destroy view]

  # GET /student_tasks
  def list
    # Authentication Tasks
    # if current_user.is_new_user
    #   redirect_to(controller: 'eula', action: 'display')
    # end
    # session[:user] = User.find_by(id: current_user.id)
    puts current_user.name
    @student_tasks = StudentTask.from_user current_user

    # Uncomment the following lines if needed:
    # Filter tasks based on availability
    # @student_tasks = @student_tasks.select { |t| t.assignment.availability_flag }

    # Filter tasks by status
    # @tasknotstarted = @student_tasks.select(&:not_started?)
    # @taskrevisions = @student_tasks.select(&:revision?)

    # Get teammates
    # @students_teamed_with = StudentTask.teamed_students(current_user, session[:ip])

    render json: @student_tasks
  end

  # GET /student_task/view
  def view
    # We use @student_task to access the participant
    @participant = @student_task.participant

    # Checking if the participant can perform submission, review, or take quizzes
    @can_submit = @participant.can_submit
    @can_review = @participant.can_review
    @can_take_quiz = @participant.can_take_quiz

    # Authorization for the current stage of the task
    @authorization = @participant.authorization

    # Getting the team associated with the participant
    @team = @participant.team

    # Ensuring the current user has permission to view this participant's information
    return denied unless current_user_id?(@participant.user_id)

    # Assignment-related checks and setup
    # Fetching the assignment related to the participant
    @assignment = @participant.assignment

    # Checking if suggestions are allowed for the assignment
    @can_provide_suggestions = @assignment.allow_suggestions

    # Fetching topics for the assignment
    @topics = SignUpTopic.where(assignment_id: @assignment.id)

    # Checking if bookmarks are used in the assignment
    @use_bookmark = @assignment.use_bookmark

    # Timeline setup
    # Generating timeline data for the assignment based on participant and team
    @timeline_list = StudentTask.get_timeline_data(@assignment, @participant, @team)

    # Email functionality setup
    # Fetching review mappings if the participant is part of a team
    @review_mappings = review_mappings(@assignment, @team.id) if @team

    # Rendering the JSON response with all the necessary information for the view
    render json: {
      can_submit: @can_submit,
      can_review: @can_review,
      can_take_quiz: @can_take_quiz,
      authorization: @authorization,
      team: @team,
      assignment: @assignment,
      can_provide_suggestions: @can_provide_suggestions,
      topics: @topics,
      timeline_list: @timeline_list,
      review_mappings: @review_mappings
    }
  end

  private
  # GET /student_tasks/1
  def show
    render json: @student_task
  end

  # POST /student_tasks
  def create
    @student_task = StudentTask.new(student_task_params)

    if @student_task.save
      render json: @student_task, status: :created, location: @student_task
    else
      render json: @student_task.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /student_tasks/1
  def update
    if @student_task.update(student_task_params)
      render json: @student_task
    else
      render json: @student_task.errors, status: :unprocessable_entity
    end
  end

  # DELETE /student_tasks/1
  def destroy
    @student_task.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_student_task
    @student_task = StudentTask.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def student_task_params
    params.require(:student_task).permit(:assignment_id, :current_stage, :participant_id, :stage_deadline, :topic)
  end

  # Method to check access rights
  def denied
    render json: { error: 'You do not have permission to view this task.' }, status: :unauthorized
  end

  def current_user_id?(user_id)
    current_user && current_user.id == user_id
  end
end
