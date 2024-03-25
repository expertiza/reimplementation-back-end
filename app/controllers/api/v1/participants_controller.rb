class Api::V1::ParticipantsController < ApplicationController
  before_action :find_user, only: :create
  before_action :find_assignment, only: :create
  # POST /participants
  def create
    participant = Participant.new(participant_params)

    if participant.save
      render json: participant, status: :created
    else
      render json: participant.errors, status: :unprocessable_entity
    end
  end

  private

  # to fetch user
  def find_user
    unless User.exists?(params[:participant][:user_id])
      render json: { error: 'User does not exist' }, status: :not_found and return
    end
  end

  #to find assignment in the db
  def find_assignment
    unless Assignment.exists?(params[:participant][:assignment_id])
      render json: { error: 'Assignment does not exist' }, status: :not_found and return
    end
  end

  #to check params of a participant
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id)
  end
end
