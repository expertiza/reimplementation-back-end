class QuestionTypesController < ApplicationController
  # GET /item_types
  def index
    question_types = QuestionType.all
    render json: question_types
  end
end
