class Api::V1::StudentTasksController < ApplicationController

    # GET /student_tasks
    def list
      @student_tasks = StudentTask.from_user current_user
      render json: @student_tasks
    end
  
    # GET /student_tasks/1
    def show
      render json: @student_task
    end
  


  end
  