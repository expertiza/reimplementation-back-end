class Api::V1::ParticipantsController < ApplicationController
  include ParticipantsHelper

  # Returns true if the user has TA privileges; otherwise, denies access by returning false.
  def has_required_role?(i)
    # code here
    puts "current user id: #{current_user.role_id}" if current_user
    return true
  end

  # Returns true if the user has TA privileges; otherwise, denies access by returning false.
  def action_allowed?
    has_required_role?('Teaching Assistant')
  end

  # Return a list of participants for a given user
  # params - user_id
  # GET /participants/user/:user_id
  def list_user_participants
    user = find_user if params[:user_id].present?
    return if params[:user_id].present? && user.nil?

    participants = filter_user_participants(user)

    if participants.nil?
      render json: participants.errors, status: :unprocessable_entity
    else
      render json: participants, status: :ok
    end
  end

  # Return a list of participants for a given assignment
  # params - assignment_id
  # GET /participants/assignment/:assignment_id
  def list_assignment_participants
    assignment = find_assignment if params[:assignment_id].present?
    return if params[:assignment_id].present? && assignment.nil?

    participants = filter_assignment_participants(assignment)

    if participants.nil?
      render json: participants.errors, status: :unprocessable_entity
    else
      render json: participants, status: :ok
    end
  end

  # Return a specified participant
  # params - id
  # GET /participants/:id
  def show
    participant = Participant.includes(team: :participants).find_by(id: params[:id])

    if participant.nil?
      render json: { error: "Participant not found" }, status: :not_found
    else
      render json: participant, status: :ok
    end
  end

  # Assign the specified authorization to the participant and add them to an assignment
  # POST /participants/:authorization
  def add
    user = find_user
    return unless user

    assignment = find_assignment
    return unless assignment

    authorization = validate_authorization
    return unless authorization

    permissions = retrieve_participant_permissions(authorization)

    participant = assignment.add_participant(user)
    participant.authorization = authorization
    participant.can_submit = permissions[:can_submit]
    participant.can_review = permissions[:can_review]
    participant.can_take_quiz = permissions[:can_take_quiz]
    participant.can_mentor = permissions[:can_mentor]

    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Update the specified participant to the specified authorization
  # PATCH /participants/:id/:authorization
  def update_authorization
    participant = find_participant
    return unless participant

    authorization = validate_authorization
    return unless authorization

    permissions = retrieve_participant_permissions(authorization)

    participant.authorization = authorization
    participant.can_submit = permissions[:can_submit]
    participant.can_review = permissions[:can_review]
    participant.can_take_quiz = permissions[:can_take_quiz]
    participant.can_mentor = permissions[:can_mentor]

    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Delete a participant
  # params - id
  # DELETE /participants/:id
  def destroy
    participant = Participant.find_by(id: params[:id])
  
    if participant.nil?
      render json: { error: 'Not Found' }, status: :not_found
    elsif participant.destroy
      successful_deletion_message = if params[:team_id].nil?
                                      "Participant #{params[:id]} in Assignment #{params[:assignment_id]} has been deleted successfully!"
                                    else
                                      "Participant #{params[:id]} in Team #{params[:team_id]} of Assignment #{params[:assignment_id]} has been deleted successfully!"
                                    end
      render json: { message: successful_deletion_message }, status: :ok
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Permitted parameters for creating a Participant object
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id, :authorization, :can_submit,
                                        :can_review, :can_take_quiz, :can_mentor, :handle,
                                        :team_id, :join_team_request_id, :permission_granted,
                                        :topic, :current_stage, :stage_deadline)
  end


  def save_grade
    puts "id: #{params[:id]}"
    puts "grade: #{params[:grade]}"
    puts "comment: #{params[:comment]}"
    puts "Grade"
  end



  def peer_reviews
    # participant = Participant.find_by(id: params[:id])
    participant = find_participant
    questionnaire = AssignmentQuestionnaire.includes(:questionnaire).find_by(id: participant.assignment_id)

    # If there are no questionnaires associated with this participant's assignment.
    if questionnaire.nil?
      render json: questionnaire, status: :ok
    end

    quest = questionnaire.questionnaire
    questions = quest.items

    response_maps = ResponseMap.includes(response: :scores).where(reviewee_id: params[:id])
    puts response_maps.inspect

    maps = ResponseMap.where(reviewee_id: params[:id])
    puts maps.first.response
    puts "GETTING REVIEWS"
    # render json: questionnaire.to_json, status: :ok

    output = {
      questionnaire: {
        id: quest.id,
        name: quest.name,
        questions: questions.map do |question|
          {
            id: question.id,
            text: question.txt,
            weight: question.weight,
            seq: question.seq,
            question_type: question.question_type,
            size: question.size,
            alternatives: question.alternatives,
            max_label: question.max_label,
            min_label: question.min_label
          }
        end
      },
      responses: maps.map do |map|
        {
          reviewer_id: map.reviewer_id,
          map_id: map.id,
          responses: map.response.map do |response|
            {
              id: response.id,
              additional_comment: response.additional_comment,
              answers: response.scores.map do |score|
                {
                  question_id: score.item_id,
                  answer: score.answer,
                  comments: score.comments
                }
              end
            }
          end
        }
      end
    }

    render json: output, status: :ok
  end


  def peer_reviews
    participant = find_participant
    questionnaire = AssignmentQuestionnaire.includes(:questionnaire).find_by(id: participant.assignment_id)

    # If there are no questionnaires associated with this participant's assignment.
    if questionnaire.nil?
      render json: questionnaire, status: :ok
    end

    quest = questionnaire.questionnaire
    questions = quest.items

    response_maps = ResponseMap.includes(response: :scores).where(reviewee_id: params[:id])
    puts response_maps.inspect

    maps = ResponseMap.where(reviewee_id: params[:id])
    puts maps.first.response
    puts "GETTING REVIEWS"
    # render json: questionnaire.to_json, status: :ok

    output = {
      questionnaire: {
        id: quest.id,
        name: quest.name,
        questions: questions.map do |question|
          {
            id: question.id,
            text: question.txt,
            weight: question.weight,
            seq: question.seq,
            question_type: question.question_type,
            size: question.size,
            alternatives: question.alternatives,
            max_label: question.max_label,
            min_label: question.min_label
          }
        end
      },
      responses: maps.map do |map|
        {
          reviewer_id: map.reviewer_id,
          map_id: map.id,
          responses: map.response.map do |response|
            {
              id: response.id,
              additional_comment: response.additional_comment,
              answers: response.scores.map do |score|
                {
                  question_id: score.item_id,
                  answer: score.answer,
                  comments: score.comments
                }
              end
            }
          end
        }
      end
    }

    render json: output, status: :ok
  end


  private

  # Filters participants based on the provided user
  # Returns participants ordered by their IDs
  def filter_user_participants(user)
    participants = Participant.all
    participants = participants.where(user_id: user.id) if user
    participants.order(:id)
  end

  # Filters participants based on the provided assignment
  # Returns participants ordered by their IDs
  def filter_assignment_participants(assignment)
    participants = Participant.all
    participants = participants.where(assignment_id: assignment.id) if assignment
    participants.order(:id)
  end

  # Finds a user based on the user_id parameter
  # Returns the user if found
  def find_user
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    render json: { error: 'User not found' }, status: :not_found unless user
    user
  end

  # Finds an assignment based on the assignment_id parameter
  # Returns the assignment if found
  def find_assignment
    assignment_id = params[:assignment_id]
    assignment = Assignment.find_by(id: assignment_id)
    render json: { error: 'Assignment not found' }, status: :not_found unless assignment
    assignment
  end

  # Finds a participant based on the id parameter
  # Returns the participant if found
  def find_participant
    participant_id = params[:id]
    participant = Participant.find_by(id: participant_id)
    render json: { error: 'Participant not found' }, status: :not_found unless participant
    participant
  end

  # Validates that the authorization parameter is present and is one of the following valid authorizations: reader, reviewer, submitter, mentor
  # Returns the authorization if valid
  def validate_authorization
    valid_authorizations = %w[reader reviewer submitter mentor]
    authorization = params[:authorization]
    authorization = authorization.downcase if authorization.present?

    unless authorization
      render json: { error: 'authorization is required' }, status: :unprocessable_entity
      return
    end

    unless valid_authorizations.include?(authorization)
      render json: { error: 'authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor' },
             status: :unprocessable_entity
      return
    end

    authorization
  end


  def participant_with_team(participant)
    user = User.find_by(id: participant.user_id)
    {
      id: participant.id,
      name: user.full_name,
      team: participant.team ? {
        id: participant.team.id,
        name: participant.team.name,
        participants: participant.team.participants.map do |p|
          {
            id: p.id,
            name: User.find_by(id: p.user_id).name,
          }
        end
      } : nil
    }
    end
end
