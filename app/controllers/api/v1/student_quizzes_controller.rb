class Api::V1::StudentQuizzesController < ApplicationController
  def index
    @quizzes = Questionnaire.all
    render json: @quizzes
  end
end
