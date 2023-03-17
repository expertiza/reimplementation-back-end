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

  def add_new_questions
    questionnaire_id = params[:id] unless params[:id].nil?
    puts "IN ADD NEW QUES!"
    puts params.inspect
    # If the questionnaire is being used in the active period of an assignment, delete existing responses before adding new questions
    if Api::V1::AnswerHelper.check_and_delete_responses(questionnaire_id)
      success_msg += 'You have successfully added a new question. Any existing reviews for the questionnaire have been deleted!'
    else
      success_msg += 'You have successfully added a new question.'
    end

    num_of_existed_questions = Questionnaire.find(questionnaire_id).questions.size
    ((num_of_existed_questions + 1)..(num_of_existed_questions + params[:question][:total_num].to_i)).each do |i|
      question = Object.const_get(params[:question][:type]).create(txt: '', questionnaire_id: questionnaire_id, seq: i, type: params[:question][:type], break_before: true)
      if question.is_a? ScoredQuestion
        question.weight = params[:question][:weight]
        question.max_label = 'Strongly agree'
        question.min_label = 'Strongly disagree'
      end

      question.size = '50, 3' # if question.is_a? Criterion
      begin
        question.save
        render json: success_msg
      rescue StandardError
        render json: $ERROR_INFO
      end
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
