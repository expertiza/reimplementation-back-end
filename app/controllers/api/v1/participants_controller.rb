class Api::V1::ParticipantsController < ApplicationController
  # Return a list of participants
  # GET /participants
  def index
    participants = Participant.order(:id)
    render json: participants, status: :ok
  end

  # Return a specified participant
  # GET /participants/:id
  def show
    participant = Participant.find(params[:id])
    render json: participant, status: :ok
  end

  # Create a participant
  # POST /participants
  def create
    participant = Participant.new(participant_params)
    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  # Delete a specified participant
  # DELETE /participants/:id
  def destroy; end

  # Permitted parameters for creating or updating a Participant object
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id, :permission_granted, :join_team_request_id,
                                        :team_id, :topic, :current_stage, :stage_deadline)
  end
end