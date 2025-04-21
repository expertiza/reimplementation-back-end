class Api::V1::ParticipantsController < ApplicationController
  include ParticipantsHelper

  # GET /participants/user/:user_id
  # Fetches all participants associated with the specified user.
  # Params:
  # - user_id [Integer]: ID of the user
  # Returns:
  # - 200 OK: A JSON array of participant objects
  # - 401 Unauthorized: If the user is not authorized for the action
  # - 404 Not Found: If the user does not exist
  # - 422 Unprocessable Entity: If the query fails unexpectedly
  def get_participants_by_user
    user = find_user if params[:user_id].present?
    return if params[:user_id].present? && user.nil?

    participants = filter_participants_by_user(user)

    if participants.nil?
      render json: participants.errors, status: :unprocessable_entity
    else
      render json: participants, status: :ok
    end
  end

  # GET /participants/assignment/:assignment_id
  # Retrieves all participants enrolled in a given assignment.
  # Params:
  # - assignment_id [Integer]: ID of the assignment
  # Returns:
  # - 200 OK: A JSON array of participant objects
  # - 401 Unauthorized: If the user is not authorized for the action
  # - 404 Not Found: If the assignment does not exist
  # - 422 Unprocessable Entity: If the query fails unexpectedly
  def get_participants_by_assignment
    assignment = find_assignment if params[:assignment_id].present?
    return if params[:assignment_id].present? && assignment.nil?

    participants = filter_participants_by_assignments(assignment)

    if participants.nil?
      render json: participants.errors, status: :unprocessable_entity
    else
      render json: participants, status: :ok
    end
  end

  # GET /participants/:id
  # Fetches a single participant by their unique ID.
  # Params:
  # - id [Integer]: ID of the participant
  # Returns:
  # - 200 OK: JSON representation of the participant
  # - 401 Unauthorized: If the user is not authorized for the action
  # - 404 Not Found: If the participant does not exist
  # - 422 Unprocessable Entity: If the participant lookup fails
  def show
    participant = Participant.find(params[:id])

    if participant.nil?
      render json: participant.errors, status: :unprocessable_entity
    else
      render json: participant, status: :ok
    end
  end

  # POST /participants/:authorization
  # Creates a new participant for a given user and assignment, and assigns
  # permissions based on the specified role (authorization).
  # Params:
  # - authorization [String]: Role to assign (reader, reviewer, submitter, mentor)
  # - participant[user_id] [Integer]: ID of the user
  # - participant[assignment_id] [Integer]: ID of the assignment
  # Returns:
  # - 201 Created: Participant successfully created
  # - 404 Not Found: If the user or assignment is not found
  # - 404 Not Found: If the assignment is not found
  # - 404 Not Found: If the user_id is missing in response body
  # - 404 Not Found: If the assignment_id is missing in response body
  # - 500 Already Exists: If the participant already exists
  # - 422 Unprocessable Entity: If the role is invalid or saving fails
  def add_participant_to_assignment
    user = find_user
    return unless user

    assignment = find_assignment
    return unless assignment

    authorization = validate_authorization
    return unless authorization

    participant = assignment.add_participant(user)
    assign_participant_permissions(authorization, participant)

    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # PATCH /participants/:id/:authorization
  # Updates the role/authorization of an existing participant.
  # Params:
  # - id [Integer]: ID of the participant
  # - authorization [String]: New role to assign (reader, reviewer, submitter, mentor)
  # Returns:
  # - 201 Created: Participant successfully updated
  # - 401 Unauthorized: If the user is not authorized for the action
  # - 404 Not Found: If participant is not found
  # - 422 Unprocessable Entity: If the authorization is invalid or update fails
  def update_authorization
    participant = find_participant
    return unless participant

    authorization = validate_authorization
    return unless authorization

    assign_participant_permissions(authorization, participant)

    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # DELETE /participants/:id
  # Deletes a participant from the system.
  # Optionally includes assignment_id and team_id for context in the response.
  # Params:
  # - id [Integer]: ID of the participant to delete
  # - assignment_id [Integer, optional]
  # - team_id [Integer, optional]
  # Returns:
  # - 200 OK: Success message indicating deletion
  # - 401 Unauthorized: If the user is not authorized for the action
  # - 404 Not Found: If participant does not exist
  # - 422 Unprocessable Entity: If deletion fails
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

  private

  # Filters participants based on the provided user
  # Returns participants ordered by their IDs
  def filter_participants_by_user(user)
    participants = Participant.where(user_id: user.id) if user
    participants.order(:id)
  end

  # Filters participants based on the provided assignment
  # Returns participants ordered by their IDs
  def filter_participants_by_assignments(assignment)
    participants = Participant.where(assignment_id: assignment.id) if assignment
    participants.order(:id)
  end

  ## Finds a user by user_id param.
  # Returns:
  # - User object if found
  # - Renders 404 if not found
  def find_user
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    render json: { error: 'User not found' }, status: :not_found unless user
    user
  end

  # Finds an assignment by assignment_id param.
  # Returns:
  # - Assignment object if found
  # - Renders 404 if not found
  def find_assignment
    assignment_id = params[:assignment_id]
    assignment = Assignment.find_by(id: assignment_id)
    render json: { error: 'Assignment not found' }, status: :not_found unless assignment
    assignment
  end

  # Finds a participant by id param.
  # Returns:
  # - Participant object if found
  # - Renders 404 if not found
  def find_participant
    participant_id = params[:id]
    participant = Participant.find_by(id: participant_id)
    render json: { error: 'Participant not found' }, status: :not_found unless participant
    participant
  end

  # An authorization string containing the participant's role is taken and used to determine
  # what permissions will be allocated to the participant. Each of these permissions will
  # then be assigned to the Participant's database permission attributes.
  #
  # @param [String] authorization: An authorization string that represents the participant's role
  # @param [Participant] participant: The participant whose authorization permissions are being updated
  def assign_participant_permissions(authorization, participant)
    # Call helper method from participants_helper to retrieve a dictionary containing the
    # appropriate permission boolean values for the role specified by the authorization string
    permissions = retrieve_participant_permissions(authorization)

    # Assigns each of the boolean permission values to their respective database counterparts
    participant.authorization = authorization
    participant.can_submit = permissions[:can_submit]
    participant.can_review = permissions[:can_review]
    participant.can_take_quiz = permissions[:can_take_quiz]
    participant.can_mentor = permissions[:can_mentor]
  end

  # Validates that the authorization parameter is present and is one of the following valid authorizations: reader, reviewer, submitter, mentor
  # Returns:
  # - authorization [String] if valid
  # - Renders 422 if missing or invalid
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
