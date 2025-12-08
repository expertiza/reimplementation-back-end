class QuestionnaireTypesController < ApplicationController
  # GET /questionnaire_types
  def index
    questionnaire_types = QuestionnaireType.all
    render json: questionnaire_types
  end
end
