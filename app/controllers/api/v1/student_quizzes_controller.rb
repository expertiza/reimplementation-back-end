module Api
  module V1
    class StudentQuizzesController < ApplicationController
      before_action :authenticate_request!
      before_action :check_instructor_role, except: [:submit_answers]
      before_action :set_student_quiz, only: [:show, :edit, :update, :destroy]


      # GET /student_quizzes
      def index
        @quizzes = Questionnaire.all
        render json: @quizzes
      end

      # GET /student_quizzes/:id
      def show
        render json: @student_quiz
      end

      # GET /student_quizzes/:id/calculate_score
      def calculate_score
        # Find the ResponseMap by its ID.
        # Make sure this ID is the ID of the ResponseMap, not the Questionnaire or the Participant.
        response_map = ResponseMap.find_by(id: params[:id])

        if response_map
          # Return the score of the ResponseMap
          render json: { score: response_map.score }, status: :ok
        else
          render json: { error: 'Attempt not found or you do not have permission to view this score.' }, status: :not_found
        end
      end

      # POST /student_quizzes/assign
      def assign_quiz_to_student
        participant = Participant.find(params[:participant_id])
        questionnaire = Questionnaire.find(params[:questionnaire_id])

        # Check if the quiz is already assigned
        existing_map = ResponseMap.find_by(
          reviewee_id: participant.user_id,
          reviewed_object_id: questionnaire.id
        )

        if existing_map
          render json: { error: "This student is already assigned to the quiz." }, status: :unprocessable_entity
          return
        end

        student_id = participant.user_id

        instructor_id = Assignment.find(questionnaire.assignment_id).instructor_id

        response_map = ResponseMap.new(
          reviewee_id: student_id,
          reviewer_id: instructor_id,
          reviewed_object_id: questionnaire.id
        )

        if response_map.save
          # Handle success
        else
          render json: { error: response_map.errors.full_messages.to_sentence }, status: :unprocessable_entity
        end
      end

      # POST /student_quizzes/create_questionnaire
      def create_questionnaire
        ActiveRecord::Base.transaction do
          questionnaire = Questionnaire.create!(questionnaire_params.except(:questions_attributes))

          questionnaire_params[:questions_attributes].each do |question_attributes|
            question = questionnaire.questions.create!(question_attributes.except(:answers_attributes))

            question_attributes[:answers_attributes].each do |answer_attributes|
              question.answers.create!(answer_attributes)
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /student_quizzes/submit_answers
      # Method to submit answers for a quiz
      def submit_answers
        ActiveRecord::Base.transaction do
          # Find the existing ResponseMap for this user and questionnaire
          response_map = ResponseMap.find_by(
            reviewee_id: current_user.id,
            reviewed_object_id: params[:questionnaire_id]
          )

          # If no ResponseMap exists for the current user, do not proceed
          unless response_map
            render json: { error: "You are not assigned to take this quiz." }, status: :forbidden
            return
          end

          # Calculate the total score based on correct answers
          total_score = params[:answers].sum do |answer|
            question = Question.find(answer[:question_id])
            submitted_answer = answer[:answer_value]

            # Find or initialize the response for the question
            response = Response.find_or_initialize_by(
              response_map_id: response_map.id,
              question_id: question.id
            )
            response.submitted_answer = submitted_answer
            response.save!

            # Increment score if the answer is correct
            question.correct_answer == submitted_answer ? question.score_value : 0
          end

          # Update the score of the ResponseMap
          response_map.update!(score: total_score)

          render json: { total_score: total_score }, status: :ok
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # PATCH/PUT /student_quizzes/:id
      def update
        if @student_quiz.update(questionnaire_params)
          render json: @student_quiz
        else
          render json: @student_quiz.errors, status: :unprocessable_entity
        end
      end

      # DELETE /student_quizzes/:id
      def destroy
        @student_quiz.destroy
        head :no_content
      end

      private

      def set_student_quiz
        @student_quiz = Questionnaire.find(params[:id])
      end

      def questionnaire_params
        params.require(:questionnaire).permit(
          :name, :instructor_id, :min_question_score, :max_question_score, :assignment_id,
          questions_attributes: [:id, :txt, :question_type, :break_before, :correct_answer, :score_value,
                                 answers_attributes: [:id, :answer_text, :correct]
          ]
        )
      end


      # New method to permit parameters for submitting answers
      def response_map_params
        params.require(:response_map).permit(:student_id, :questionnaire_id)
      end

      # Check for instructor
      def check_instructor_role
        unless current_user.role_id == 3
          render json: { error: 'Only instructors are allowed to perform this action' }, status: :forbidden
          return
        end
      end

    end
  end
end
