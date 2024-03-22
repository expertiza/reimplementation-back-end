class Api::V1::ParticipantsController < ApplicationController
  # POST /api/v1/participants
  def create
    # Check if the user and the assignment exist
    unless User.exists?(participant_params[:user_id])
      return render json: { error: 'User does not exist' }, status: :not_found
    end

    unless Assignment.exists?(participant_params[:assignment_id])
      return render json: { error: 'Assignment does not exist' }, status: :not_found
    end

    # Instantiate a new Participant object with the permitted parameters
    participant = Participant.new(participant_params)

    # Attempt to save the Participant object to the database
    if participant.save
      # If save is successful, respond with the participant object and status code 201 (Created)
      render json: participant, status: :created
    else
      # If save fails, respond with the error messages and status code 422 (Unprocessable Entity)
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  private

  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id)
  end
end