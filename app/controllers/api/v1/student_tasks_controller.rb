class Api::V1::StudentTasksController < ApplicationController
    before_action :set_student_task, only: %i[ show ]

    # GET /student_tasks
    def list
      @student_tasks = StudentTask.from_user current_user
      render json: @student_tasks
    end
  
    # GET /student_tasks/1
    def show
      render json: @student_task
    end
  


    private
      # Use callbacks to share common setup or constraints between actions.
      def set_student_task
        @student_task = StudentTask.find(params[:id])
      end

  end
  