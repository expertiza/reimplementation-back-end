class Api::V1::QuizQuestionnairesController < ApplicationController

  def show
    begin
      @questionnaire = Questionnaire.find(params[:id])
      render json: @questionnaire, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  def create
    begin
      # render json: params, status: :accepted and return

      @assignment_id = params[:assignmnet_id] # creating an instance variable to hold the assignment id
      @participant_id = params[:participant_id] # creating an instance variable to hold the participant id
      @team_id = params[:team_id]

      assignment = Assignment.find(@assignment_id)

      # render json: assignment, status: :created and return

      if assignment.require_quiz?
        valid_request = team_valid?(@team_id, @participant_id) # check for validity of the request
      else
        @err = 'This assignment is not configured to use quizzes.'
        render json: @err, status: :bad_request
        valid_request = false
      end

      # render json: valid_request, status: :accepted and return

      if valid_request && check_questionnaire_type(params[:questionnaire_type])

        @questionnaire = QuizQuestionnaire.new(questionnaire_params)
        @questionnaire.instructor_id = @team_id
        @questionnaire.display_type = params[:questionnaire_type].split('Questionnaire')[0]
        @questionnaire.assignment_id = @assignment_id
        # render json: @questionnaire, status: :ok and return

        if @questionnaire.min_question_score < 0 || @questionnaire.max_question_score < 0
          err = 'Minimum and/or maximum question score cannot be less than 0.'
          render json: err, status: :unprocessable_entity and return
        elsif @questionnaire.max_question_score < @questionnaire.min_question_score
          err = 'Maximum question score cannot be less than minimum question score.'
          render json: err, status: :unprocessable_entity and return
        else
          @questionnaire.save
          render json: @questionnaire, status: :created and return
        end

      else
        @err = 'Validation Errors.'
        render json: @err, status: :bad_request
      end

    end

  end

  def team_valid?(team_id, participant_id)
    participantTeamID = Participant.find(participant_id).team_id
    team_id.eql?(participantTeamID)
  end

  #

  def destroy
    begin
      @questionnaire = Questionnaire.find(params[:id])
      @questionnaire.delete
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end
  end

  def update
    @questionnaire = Questionnaire.find(params[:id])
    if @questionnaire.update(questionnaire_params)
      render json: @questionnaire, status: :ok
    else
      render json: @questionnaire.errors.full_messages, status: :unprocessable_entity
    end
  end




  # def update
    #   begin
    #     @questionnaire = Questionnaire.find(params[:id])
    #
    #     if @questionnaire.nil?
    #       @err = 'Empty Questionnaire, make sure the correct ID is sent.'
    #       render json: @err, status: :bad_request and return
    #     end
    #
    #     if @questionnaire.taken_by_anyone?
    #       @err = 'Your quiz has been taken by one or more students; you cannot edit it anymore.'
    #       render json: @err, status: :bad_request and return
    #     end
    #     # quiz can be edited only if its not taken by anyone
    #     @assignment_id = params[:assignmnetID] # creating an instance variable to hold the assignment id
    #     @participant_id = params[:participantID] # creating an instance variable to hold the participant id
    #     @team_id = params[:teamID]
    #
    #     user = User.find(Participant.find(@participant_id))
    #     role = Role.find(user.role_id)
    #
    #     if role.eql?("Student") || role.eql?("Administrator")
    #       if @questionnaire.update(questionnaire_params)
    #
    #         params[:question].each_pair do |qid, _|
    #           @question = Question.find(qid)
    #           @question.txt = params[:question][qid.to_sym][:txt]
    #           @question.weight = params[:question_weights][qid.to_sym][:txt]
    #           @question.save
    #           @quiz_question_choices = QuizQuestionChoice.where(question_id: qid)
    #           question_index = 1
    #           @quiz_question_choices.each do |question_choice|
    #             # Updates state of each question choice for selected question
    #             # Call private methods to handle question types
    #             update_checkbox(question_choice, question_index) if @question.type == 'MultipleChoiceCheckbox'
    #             update_radio(question_choice, question_index) if @question.type == 'MultipleChoiceRadio'
    #             update_truefalse(question_choice) if @question.type == 'TrueFalse'
    #             question_index += 1
    #           end
    #         end
    #         render json: @questionnaire, status: :ok
    #       else
    #         render json: @questionnaire.errors.full_messages, status: :unprocessable_entity
    #       end
    #
    #     else
    #       @err = 'You do not have the permission to edit this questionnaire.'
    #       render json: @err, status: :bad_request
    #     end
    #
    #   end
    # end

  # def update_checkbox(question_choice, question_index)
  #   if params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s]
  #     question_choice.update_attributes(
  #       iscorrect: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:iscorrect],
  #       txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
  #     )
  #   else
  #     question_choice.update_attributes(
  #       iscorrect: '0',
  #       txt: params[:quiz_question_choices][question_choice.id.to_s][:txt]
  #     )
  #   end
  # end
  #
  # # update radio item
  # def update_radio(question_choice, question_index)
  #   if params[:quiz_question_choices][@question.id.to_s][@question.type][:correctindex] == question_index.to_s
  #     question_choice.update_attributes(
  #       iscorrect: '1',
  #       txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
  #     )
  #   else
  #     question_choice.update_attributes(
  #       iscorrect: '0',
  #       txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
  #     )
  #   end
  # end
  #
  # # update true/false item
  # def update_truefalse(question_choice)
  #   if params[:quiz_question_choices][@question.id.to_s][@question.type][1.to_s][:iscorrect] == 'True' # the statement is correct
  #     question_choice.txt == 'True' ? question_choice.update_attributes(iscorrect: '1') : question_choice.update_attributes(iscorrect: '0')
  #     # the statement is correct so "True" is the right answer
  #   else
  #     # the statement is not correct
  #     question_choice.txt == 'True' ? question_choice.update_attributes(iscorrect: '0') : question_choice.update_attributes(iscorrect: '1')
  #     # the statement is not correct so "False" is the right answer
  #   end
  # end

  private

  def questionnaire_params
    params.require(:quiz_questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id, :assignment_id)
  end

  def check_questionnaire_type(type)
    type.eql?("Quiz Questionnaire")
  end

end

