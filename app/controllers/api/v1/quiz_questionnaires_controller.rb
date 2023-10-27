class Api::V1::QuizQuestionnairesController < QuestionnairesController

  def index
    begin
      @questionnaire = Questionnaire.find(params[:id])
      render json: @questionnaire, status: :ok and return
    rescue ActiveRecord::RecordNotFound
      render json: $ERROR_INFO.to_s, status: :not_found and return
    end

    def create
      begin
        valid_request = true # A request is valid if the assignment requires a quiz, the participant has a team, and that team has a topic if the assignment has a topic
        @assignment_id = params[:assignmnetID] # creating an instance variable to hold the assignment id
        @participant_id = params[:participantID] # creating an instance variable to hold the participant id
        @team_id = params[:teamID]
        assignment = Assignment.find(@assignment_id)

        if assignment.require_quiz?
          valid_request = team_valid?(@team_id, @participant_id, assignment) # check for validity of the request
        else
          @err = 'This assignment is not configured to use quizzes.'
          render json: @err, status: :bad_request
          valid_request = false
        end
        if valid_request && check_questionnaire_type(params[:questionnaire_type])
          @questionnaire = QuizQuestionnaire.new(questionnaire_params)
          @questionnaire.instructor_id = @team_id
          @questionnaire.save

          render json: @questionnaire, status: :created and return
        end

      end

    end

    def team_valid?(team_id, participant_id, assignment)
      # team = AssignmentParticipant.find(participant_id).team
      # if team.nil? # flash error if this current participant does not have a team
      #   flash[:error] = 'You should create or join a team first.'
      #   false
      # elsif assignment.topics? && team.topic.nil? # flash error if this assignment has topic but current team does not have a topic
      #   flash[:error] = 'Your team should have a topic.'
      #   false
      # else # the current participant is part of a team that has a topic
      #   true
      # end
      true
    end

    def update
      begin
        @questionnaire = Questionnaire.find(params[:id])

        if @questionnaire.nil?
          @err = 'Empty Questionnaire, make sure the correct ID is sent.'
          render json: @err, status: :bad_request and return
        end

        if @questionnaire.taken_by_anyone?
          @err = 'Your quiz has been taken by one or more students; you cannot edit it anymore.'
          render json: @err, status: :bad_request and return
        end
        # quiz can be edited only if its not taken by anyone
        @assignment_id = params[:assignmnetID] # creating an instance variable to hold the assignment id
        @participant_id = params[:participantID] # creating an instance variable to hold the participant id
        @team_id = params[:teamID]

        user = User.find(Participant.find(@participant_id))
        role = Role.find(user.role_id)

        if role.eql?("Student") || role.eql?("Administrator")
          if @questionnaire.update(questionnaire_params)

            params[:question].each_pair do |qid, _|
              @question = Question.find(qid)
              @question.txt = params[:question][qid.to_sym][:txt]
              @question.weight = params[:question_weights][qid.to_sym][:txt]
              @question.save
              @quiz_question_choices = QuizQuestionChoice.where(question_id: qid)
              question_index = 1
              @quiz_question_choices.each do |question_choice|
                # Updates state of each question choice for selected question
                # Call private methods to handle question types
                update_checkbox(question_choice, question_index) if @question.type == 'MultipleChoiceCheckbox'
                update_radio(question_choice, question_index) if @question.type == 'MultipleChoiceRadio'
                update_truefalse(question_choice) if @question.type == 'TrueFalse'
                question_index += 1
              end
            end
            render json: @questionnaire, status: :ok
          else
            render json: @questionnaire.errors.full_messages, status: :unprocessable_entity
          end

        else
          @err = 'You do not have the permission to edit this questionnaire.'
          render json: @err, status: :bad_request
        end

      end
    end

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

    def update_checkbox(question_choice, question_index)
      if params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s]
        question_choice.update_attributes(
          iscorrect: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:iscorrect],
          txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
        )
      else
        question_choice.update_attributes(
          iscorrect: '0',
          txt: params[:quiz_question_choices][question_choice.id.to_s][:txt]
        )
      end
    end

    # update radio item
    def update_radio(question_choice, question_index)
      if params[:quiz_question_choices][@question.id.to_s][@question.type][:correctindex] == question_index.to_s
        question_choice.update_attributes(
          iscorrect: '1',
          txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
        )
      else
        question_choice.update_attributes(
          iscorrect: '0',
          txt: params[:quiz_question_choices][@question.id.to_s][@question.type][question_index.to_s][:txt]
        )
      end
    end

    # update true/false item
    def update_truefalse(question_choice)
      if params[:quiz_question_choices][@question.id.to_s][@question.type][1.to_s][:iscorrect] == 'True' # the statement is correct
        question_choice.txt == 'True' ? question_choice.update_attributes(iscorrect: '1') : question_choice.update_attributes(iscorrect: '0')
        # the statement is correct so "True" is the right answer
      else
        # the statement is not correct
        question_choice.txt == 'True' ? question_choice.update_attributes(iscorrect: '0') : question_choice.update_attributes(iscorrect: '1')
        # the statement is not correct so "False" is the right answer
      end
    end

    private

    def questionnaire_params
      params.require(:questionnaire).permit(:name, :questionnaire_type, :private, :min_question_score, :max_question_score, :instructor_id)
    end

    def check_questionnaire_type(type)
      if %w[Quiz].include?(type)
        return true
      end
      return false
    end

  end
end
