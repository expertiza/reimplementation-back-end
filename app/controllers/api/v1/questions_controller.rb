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

  def new
    @question = Question.new
  end

  def create
    @question = Question.new(question_params[:question])
    if @question.save
      render json: 'You have successfully created the question!'
    else
      render json: $ERROR_INFO
    end
  end

  # DELETE /api/v1/questions/delete/:id
  def destroy
    question = Question.find(params[:id])
    questionnaire_id = question.questionnaire_id

    success_msg = ""
    
    # if AnswerHelper.check_and_delete_responses(questionnaire_id)
    if Api::V1::AnswerHelper.check_and_delete_responses(questionnaire_id)
      success_msg += 'You have successfully deleted the question. Any existing reviews for the questionnaire have been deleted!'
    else
      success_msg += 'You have successfully deleted the question!'
    end

    begin
      question.destroy
      render json: success_msg
    rescue StandardError
      render json: $ERROR_INFO
    end
  end

  private

  def question_params
    params.permit(:id, :question)
  end

end
