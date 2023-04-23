class QuestionsController < ApplicationController

  # A question is a single entry within a questionnaire
  # Questions provide a way of scoring an object
  # based on either a numeric value or a true/false
  # state.

  # Default action, same as list
  def index
    list
    render action: 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify method: :post, only: %i[destroy create update],
         redirect_to: { action: :list }

  # List all questions in paginated view
  def list
    @questions = Question.paginate(page: params[:page], per_page: 10)
  end

  # Display a given question
  def show
    @question = Question.find(params[:id])
  end

  # Provide the user with the ability to define a new question
  def new
    @question = Question.new
  end

  # Save a question created by the user
  # follows from new
  def create
    @question = Question.new(question_params[:question])
    if @question.save
      flash[:notice] = 'The question was successfully created.'
      redirect_to action: 'list'
    else
      render action: 'new'
    end
  end

  # edit an existing question
  def edit
    @question = Question.find(params[:id])
  end

  # save the update to an existing question
  # follows from edit
  def update
    @question = Question.find(question_params[:id])
    if @question.update_attributes(question_params[:question])
      flash[:notice] = 'The question was successfully updated.'
      redirect_to action: 'show', id: @question
    else
      render action: 'edit'
    end
  end

  # Remove question from database and
  # return to list
  def destroy
    question = Question.find(params[:id])
    questionnaire_id = question.questionnaire_id

    begin
      question.destroy
    rescue StandardError
      flash[:error] = $ERROR_INFO
    end
    redirect_to edit_questionnaire_path(questionnaire_id.to_s.to_sym)
  end

  # required for answer tagging
  def types
    types = Question.distinct.pluck(:type)
    render json: types.to_a
  end

  # save questions that have been added to a questionnaire
  def save_new_questions(questionnaire_id)
    # The new_question array contains all the new questions
    # that should be saved to the database
    params[:new_question]&.keys&.each_with_index do |question_key, index|
      q = Question.new
      q.txt = params[:new_question][question_key]
      q.questionnaire_id = questionnaire_id
      q.type = params[:question_type][question_key][:type]
      q.seq = question_key.to_i
      if @questionnaire.type == 'QuizQuestionnaire'
        # using the weight user enters when creating quiz
        weight_key = "question_#{index + 1}"
        q.weight = params[:question_weights][weight_key.to_sym]
      end
      q.save unless q.txt.strip.empty?
    end
  end

  # delete questions from a questionnaire
  # @param [Object] questionnaire_id
  def delete_questions(questionnaire_id)
    # Deletes any questions that, as a result of the edit, are no longer in the questionnaire
    questions = Question.where('questionnaire_id = ?', questionnaire_id)
    @deleted_questions = []
    questions.each do |question|
      should_delete = true
      unless question_params.nil?
        params[:question].each_key do |question_key|
          should_delete = false if question_key.to_s == question.id.to_s
        end
      end

      next unless should_delete

      question.question_advices.each(&:destroy)
      # keep track of the deleted questions
      @deleted_questions.push(question)
      question.destroy
    end
  end

  # Handles questions whose wording changed as a result of the edit
  # @param [Object] questionnaire_id
  def save_questions(questionnaire_id)
    delete_questions questionnaire_id
    save_new_questions questionnaire_id

    params[:question]&.keys&.each do |question_key|
      if params[:question][question_key][:txt].strip.empty?
        # question text is empty, delete the question
        Question.delete(question_key)
      else
        # Update existing question.
        question = Question.find(question_key)
        Rails.logger.info(question.errors.messages.inspect) unless question.update_attributes(params[:question][question_key])
      end
    end
  end

  # Zhewei: This method is used to add new questions when editing questionnaire.
  def add_new_questions
    questionnaire_id = params[:id] unless params[:id].nil?
    # If the questionnaire is being used in the active period of an assignment, delete existing responses before adding new questions

    num_of_existed_questions = Questionnaire.find(questionnaire_id).questions.size
    ((num_of_existed_questions + 1)..(num_of_existed_questions + params[:question][:total_num].to_i)).each do |i|
      question = Object.const_get(params[:question][:type]).create(txt: '', questionnaire_id: questionnaire_id, seq: i, type: params[:question][:type], break_before: true)
      if question.is_a? ScoredQuestion
        question.weight = params[:question][:weight]
        question.max_label = 'Strongly agree'
        question.min_label = 'Strongly disagree'
      end

      question.size = '50, 3' if question.is_a? Criterion
      question.size = '50, 3' if question.is_a? Cake
      question.alternatives = '0|1|2|3|4|5' if question.is_a? Dropdown
      question.size = '60, 5' if question.is_a? TextArea
      question.size = '30' if question.is_a? TextField

      begin
        question.save
      rescue StandardError
        flash[:error] = $ERROR_INFO
      end
    end
    redirect_to edit_questionnaire_path(questionnaire_id.to_sym)
  end

  # Zhewei: This method is used to save all questions in current questionnaire.
  def save_all_questions
    questionnaire_id = params[:id]
    begin
      if params[:save]
        params[:question].each_pair do |k, v|
          @question = Question.find(k)
          # example of 'v' value
          # {"seq"=>"1.0", "txt"=>"WOW", "weight"=>"1", "size"=>"50,3", "max_label"=>"Strong agree", "min_label"=>"Not agree"}
          v.each_pair do |key, value|
            @question.send("#{key}=", value) unless @question.send(key) == value
          end

          @question.save
          flash[:success] = 'All questions have been successfully saved!'
        end
      end
    rescue StandardError
      flash[:error] = $ERROR_INFO
    end

    if params[:view_advice]
      redirect_to controller: 'advice', action: 'edit_advice', id: params[:id]
    elsif questionnaire_id
      redirect_to edit_questionnaire_path(questionnaire_id.to_sym)
    end
  end

  # Only allow a list of trusted parameters through.
  def question_params
    params.require(:question).permit(:txt, :weight, :questionnaire_id, :seq, :type, :size,
                                     :alternatives, :break_before, :max_label, :min_label)
  end
end
