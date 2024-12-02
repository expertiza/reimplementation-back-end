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

  # Assign the specified role to the participant and add them to an assignment
  # POST /participants/:role
  def add
    user = find_user
    return unless user

    assignment = find_assignment
    return unless assignment

    role = validate_role
    return unless role

    permissions = retrieve_participant_permissions(role)

    AssignmentParticipant.new(participant_params).tap do |participant|
      participant.user_id = user.id
      participant.assignment_id = assignment.id
      participant.role = permissions[:role]
      participant.can_submit = permissions[:can_submit]
      participant.can_review = permissions[:can_review]
      participant.can_take_quiz = permissions[:can_take_quiz]
      participant.can_mentor = permissions[:can_mentor]
    end

    assignment.add_participant(user)

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
    params.require(:participant).permit(:user_id, :assignment_id, :can_submit, :can_review, :can_take_quiz, :can_mentor,
                                        :team_id, :join_team_request_id,
                                        :permission_granted, :topic, :current_stage, :stage_deadline)
  end

  private

  def filter_participants(user, assignment)
    participants = Participant.all
    participants = participants.where(user_id: user.id) if user
    participants = participants.where(assignment_id: assignment.id) if assignment
    participants.order(:id)
  end

  def find_user
    user_id = params[:user_id]
    user = User.find_by(id: user_id)
    render json: { error: 'User not found' }, status: :not_found unless user
    user
  end

  def find_assignment
    assignment_id = params[:assignment_id]
    assignment = Assignment.find_by(id: assignment_id)
    render json: { error: 'Assignment not found' }, status: :not_found unless assignment
    assignment
  end

  def validate_role
    valid_roles = %w[reader reviewer submitter mentor]
    role = params[:role]
    role = role.downcase if role.present?

    unless role
      render json: { error: 'Role is required' }, status: :unprocessable_entity
      return
    end

    unless valid_roles.include?(role)
      render json: { error: 'Role not valid. Valid roles are: Reader, Reviewer, Submitter, Mentor' },
             status: :unprocessable_entity
      return
    end

    role
  end
end
