class Api::V1::ParticipantsController < ApplicationController
  # Return a list of participants
  # GET /participants
  def index
    participants = if params[:user_id].present?
                     Participant.where(user_id: params[:user_id]).order(:id)
                   else
                     Participant.order(:id)
                   end

    render json: participants, status: :ok
  end

  # Return a specified participant
  # GET /participants/:id
  def show
    participant = Participant.find_by(id: params[:id], user_id: params[:user_id])

    if participant
      render json: participant, status: :ok
    else
      render json: { error: 'Participant not found or does not belong to the specified user' }, status: :not_found
    end
  end

  # Create a participant
  # POST /participants
  def create
    user = find_user
    return unless user

    assignment = find_assignment
    return unless assignment

    participant = build_participant(user, assignment)
    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Delete a specified participant
  # DELETE /participants/:id
  def destroy
    participant = Participant.find(params[:id])
    if participant.destroy
      render json: { message: deletion_message(params) }, status: :ok
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Permitted parameters for creating a Participant object
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id, :team_id, :join_team_request_id,
                                        :permission_granted, :topic, :current_stage, :stage_deadline)
  end

  private

  def deletion_message(params)
    if params[:team_id].nil?
      "Participant #{params[:id]} in Assignment #{params[:assignment_id]} has been deleted successfully!"
    else
      "Participant #{params[:id]} in Team #{params[:team_id]} of Assignment #{params[:assignment_id]} has been deleted successfully!"
    end
  end

  def find_user
    user = User.find_by(id: participant_params[:user_id])
    render json: { error: 'User not found' }, status: :not_found unless user
    user
  end

  def find_assignment
    assignment = Assignment.find_by(id: participant_params[:assignment_id])
    render json: { error: 'Assignment not found' }, status: :not_found unless assignment
    assignment
  end

  def build_participant(user, assignment)
    Participant.new(participant_params).tap do |participant|
      participant.user_id = user.id
      participant.assignment_id = assignment.id
    end
  end
end
