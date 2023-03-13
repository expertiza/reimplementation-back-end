class Api::V1::QuestionsController < ApplicationController
  
  # GET /api/v1/questions/view
  def view
    @questions = Question.order(:id)
    render json: @questions
  end

  # GET /api/v1/questions/:id
  def show
    begin
    @question = Question.find(params[:id])
    render json: @question
    rescue
      error_msg = "No such Question exists."
      render json: error_msg
    end
  end

  private

  def question_params
    params.permit(:id, :question)
  end

end
