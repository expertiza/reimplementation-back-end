class Api::V1::QuestionsController < ApplicationController
  
  # GET /api/v1/questions
  def index
    @questions = Question.order(:id)
    render json: @questions
  end

  # GET /api/v1/questions/:id
  def show
    @question = Question.find(params[:id])
    render json: @question
  end

  private

  def question_params
    params.permit(:id, :question)
  end

end
