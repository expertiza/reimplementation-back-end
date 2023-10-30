class Api::V1::QuestionsController < ApplicationController
  
  # Index method returns the list of questions JSON object
  # GET on /questions
  def index
    @questions = Question.order(:id)
    render json: @questions, status: :ok
  end

  # Show method returns the question object with id - {:id}
  # GET on /questions/:id
  def show
    begin
      @question = Question.find(params[:id])
      render json: @question, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found
    end
  end

  # Create method returns the JSON object of created question
  # POST on /questions
  def create
  questionnaire_id = params[:questionnaire_id]
  questionnaire = Questionnaire.find(questionnaire_id)
  question = questionnaire.questions.build(
    txt: params[:txt],
    question_type: params[:question_type],
    break_before: true
  )

  case question.question_type
  when 'Scale'
    question.weight = params[:weight]
    question.max_label = 'Strongly agree'
    question.min_label = 'Strongly disagree'
  when 'Cake', 'Criterion'
    question.weight = params[:weight]
    question.max_label = 'Strongly agree'
    question.min_label = 'Strongly disagree'
    question.size = '50, 3'
  when 'Dropdown'
    question.alternatives = '0|1|2|3|4|5'
  when 'TextArea'
    question.size = '60, 5'
  when 'TextField'
    question.size = '30'
  end

  if question.save
    render json: question, status: :created
  else
    render json: question.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
rescue ActiveRecord::RecordNotFound
  render json: $ERROR_INFO.to_s, status: :not_found and return  
end
  

  # Destroy method deletes the question with id - {:id}
  # DELETE on /questions/:id
  def destroy
    begin
      @question = Question.find(params[:id])
      @question.destroy
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # show_all method returns all questions associated to a questionnaire with id - {:id}
  # GET on /questions/show_all/questionnaire/:id
  def show_all
    begin
      @questionnaire = Questionnaire.find(params[:id])
      @questions = @questionnaire.questions
      render json: @questions, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found
    end
  end

  # Delete_all method deletes all the questions and returns the status code
  # DELETE on /questions/delete_all/questionnaire/<questionnaire_id>
  # Endpoint to delete all questions associated to a particular questionnaire.
  
  def delete_all
    begin
      questionnaire = Questionnaire.find(params[:id])
      if questionnaire.questions.empty?
        render json: "No questions associated with questionnaire ID #{params[:id]}.", status: :unprocessable_entity and return
      end
  
      questionnaire.questions.destroy_all
      render json: "All questions for questionnaire ID #{params[:id]} have been deleted.", status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: "Questionnaire ID #{params[:id]} not found.", status: :not_found and return
    end
  end

  # Update method updates the question with id - {:id} and returns its JSON object
  # PUT on /questions/:id
  def update
    begin
      @question = Question.find(params[:id])
      if @question.update(question_params)
        render json: @question, status: :ok and return
      else
        render json: "Failed to update the question.", status: :unprocessable_entity and return
      end
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  # GET on /questions/types
  def types
    types = Question.distinct.pluck(:question_type)
    render json: types.to_a, status: :ok
  end

  private
  
  # Only allow a list of trusted parameters through.
  def question_params
    params.permit(:txt, :weight, :seq, :questionnaire_id, :question_type, :size,
                                     :alternatives, :break_before, :max_label, :min_label)
  end
end
