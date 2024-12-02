class Api::V1::ParticipantsController < ApplicationController
  include ParticipantsHelper

  # Return a list of participants for a given user or assignment
  # params - user_id
  #          assignment_id
  # GET /participants/:user_id
  # GET /participants/:assignment_id
  def index
    # Validate and find user if user_id is provided
    user = find_user if params[:user_id].present?
    return if params[:user_id].present? && user.nil?

    # Validate and find assignment if assignment_id is provided
    assignment = find_assignment if params[:assignment_id].present?
    return if params[:assignment_id].present? && assignment.nil?

    participants = filter_participants(user, assignment)

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
    participant = Participant.find(params[:id])

    if participant.nil?
      render json: participant.errors, status: :unprocessable_entity
    else
      render json: participant, status: :created
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
    participant = Participant.find(params[:id])

    if participant.destroy
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

  private

  # Filters participants based on the provided user and/or assignment
  # If a user is provided, participants are filtered by user_id
  # If an assignment is provided, participants are filtered by assignment_id
  # Returns participants ordered by their IDs
  def filter_participants(user, assignment)
    participants = Participant.all
    participants = participants.where(user_id: user.id) if user
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
end
