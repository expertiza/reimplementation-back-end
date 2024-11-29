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
    if params[:assignment_id].nil? && params[:team_id].nil?
      "Participant #{params[:id]} has been deleted successfully!"
    elsif params[:team_id].nil?
      "Participant #{params[:id]} in Assignment #{params[:assignment_id]} has been deleted successfully!"
    else
      "Participant #{params[:id]} in Team #{params[:team_id]} of Assignment #{params[:assignment_id]} has been deleted successfully!"
    end
  end
end
