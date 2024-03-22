class Api::V1::ParticipantsController < ApplicationController
  before_action :find_user, only: :create
  before_action :find_assignment, only: :create
  # POST /api/v1/participants
  def create
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

  def find_user
    unless User.exists?(params[:participant][:user_id])
      render json: { error: 'User does not exist' }, status: :not_found and return
    end
  end

  def find_assignment
    unless Assignment.exists?(params[:participant][:assignment_id])
      render json: { error: 'Assignment does not exist' }, status: :not_found and return
    end
  end
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id)
  end
end
