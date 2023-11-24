module Api
  module V1
    class ParticipantsController < ApplicationController
      # POST /api/v1/participants
      def create
        participant = Participant.new(participant_params)
        if participant.save
          render json: participant, status: :created
        else
          render json: participant.errors, status: :unprocessable_entity
        end
      end

      private

      def participant_params
        params.require(:participant).permit(:user_id, :assignment_id)
      end
    end
  end
end
