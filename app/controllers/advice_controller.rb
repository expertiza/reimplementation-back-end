class AdviceController < ApplicationController
  # Advice_controller first checks whether current user has TA privileges or not by implementing action_allowed? method. Secondly it sets the number of advices based on score and sort it in descending order. Then it checks four conditions for the advices.
  # 1. If number of advices is not equal to given advices
  # 2. If the sorted advices is empty
  # 3. If first advice score of sorted advices is NOT equal to max score
  # 4. If last advice score of sorted advices is NOT equal to min score
  # If any of the above condition are True, the edit_advice method calls adjust_advice_size of the QuestionnaireHelper class which adjust the advice sizes accordingly.
  # In the end, save_advice method is called which updates and saves the changes in the advices and displays the success/failure message.

  include AuthorizationHelper
  # If current user is TA then only current user can edit and update the advice
  def action_allowed?
    current_user_has_ta_privileges?
  end

  # checks whether the advices for a question in questionnaire have valid attributes
  # return true if the number of advices and their scores are invalid, else returns false
  def invalid_advice?(sorted_advice, num_advices, question)
    return ((question.question_advices.length != num_advices) ||
      sorted_advice.empty? ||
      (sorted_advice[0].score != @questionnaire.max_question_score) ||
      (sorted_advice[sorted_advice.length - 1].score != @questionnaire.min_question_score))
  end

  # Modify the advice associated with a questionnaire
  # Separate methods were introduced to calculate the number of advices and sort the advices related to the current question attribute
  # This is done to adhere to Single Responsibility Principle
  def edit_advice
    # Stores the questionnaire with given id in URL
    @questionnaire = Questionnaire.find(params[:id])

    # For each question in a questionnaire, this method adjusts the advice size if the advice size is <,> number of advices or
    # the max or min score of the advices does not correspond to the max or min score of questionnaire respectively.
    @questionnaire.questions.each do |question|
      # if the question is a scored question, store the number of advices corresponding to that question (max_score - min_score), else 0
      # # Call to a separate method to adhere to Single Responsibility Principle
      num_advices = calculate_num_advices(question)

      # sorting question advices in descending order by score
      # Call to a separate method to adhere to Single Responsibility Principle
      sorted_advice = sort_question_advices(question)

      # Checks the condition for adjusting the advice size
      if invalid_advice?(sorted_advice, num_advices, question)
        # The number of advices for this question has changed.
        QuestionnaireHelper.adjust_advice_size(@questionnaire, question)
      end
    end
  end

  # Function to calculate number of advices for the current question attribute based on max and min question score.
  # Method name is consistent with the functionality
  def calculate_num_advices(question)
    if question.is_a?(ScoredQuestion)
      @questionnaire.max_question_score - @questionnaire.min_question_score + 1
    else
      0
    end
  end

  # Function to sort question advices related to the current question attribute
  # While sorting questions, sort_by(&:score) is used instead of using a block. It is a shorthand notation and avoids creating a new Proc object for every element in the collection of the questions.
  def sort_question_advices(question)
    question.question_advices.sort_by(&:score).reverse
  end

  # save the advice for a questionnaire
  def save_advice
    # Stores the questionnaire with given id in URL
    @questionnaire = Questionnaire.find(params[:id])
    begin
      # checks if advice is present or not
      unless params[:advice].nil?
        params[:advice].keys.each do |advice_key|
          # Updates the advice corresponding to the key
          QuestionAdvice.update(advice_key, advice: params[:advice][advice_key.to_sym][:advice])
        end
        flash[:notice] = 'The advice was successfully saved!'
      end
    rescue ActiveRecord::RecordNotFound
      # If record not found, redirects to edit_advice
      render action: 'edit_advice', id: params[:id]
    end
    redirect_to action: 'edit_advice', id: params[:id]
  end
end