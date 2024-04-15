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

  # GET /student_tasks/1/view
  def view
    denied unless current_user_id?(@student_task.participant.user_id)

    task_details = {
      id: @student_task.participant.id,
      fullname: @student_task.participant.fullname,
      assignment_name: @student_task.assignment,
      topic: @student_task.topic,
      current_stage: @student_task.current_stage,
      # review_comment: @student_task.participant.review_comment, # Double check this method / attribute exists
      # (Not sure if necessary in table)
      has_badge: @student_task.participant.has_badge, # //TODO Check method / attribute path
      stage_deadline: @student_task.stage_deadline,
      publishing_rights: @student_task.participant.publishing_rights # //TODO Check method / attribute path
    }

    render json: task_details
  end

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
