class Api::V1::StudentTasksController < ApplicationController
    before_action :set_student_task, only: %i[ show update destroy ]

    # GET /student_tasks
    def list
  
      # Authentication Tasks
      # if current_user.is_new_user
      #   redirect_to(controller: 'eula', action: 'display')
      # end
      # session[:user] = User.find_by(id: current_user.id)
      puts current_user.name
      @student_tasks = StudentTask.from_user current_user

      # @student_tasks.select! { |t| t.assignment.availability_flag }
      #
      # # #######Tasks and Notifications##################
      # @tasknotstarted = @student_tasks.select(&:not_started?)
      # @taskrevisions = @student_tasks.select(&:revision?)
      #
      # ######## Students Teamed With###################
      # @students_teamed_with = StudentTask.teamed_students(current_user, session[:ip])
      render json: @student_tasks
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
  end
  