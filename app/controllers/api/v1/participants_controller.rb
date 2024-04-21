class Api::V1::ParticipantsController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found
    
  
    # GET /participants
    def index
      @participants = Participant.all
      render json: { participants: @participants }, status: :ok
    end
  
    # GET /participants/:id
    def show
      @participant = Participant.find(params[:id])
      render json: { participant: @participant }, status: :ok
    end
  
    # GET /participants/new
    def new
      @participant = Participant.new
      render json: { participants: @participants }, status: :ok
    end
  
    # POST /participants
    def create
      @participant = Participant.new(participant_params)
      if @participant.save
        render json: @participant, status: :created
      else
        render json: @participant.errors, status: :unprocessable_entity
      end
    end
  
    # GET /participants/:id/edit
    def edit
      @participant = Participant.find(params[:id])
    end
  
    # PATCH/PUT /participants/:id
    def update
      @participant = Participant.find(params[:id])
      if @participant.update(participant_params)
        render json: { participant: @participant }, status: :ok
      else
        render json: @participant.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /participants/:id
    def destroy
      @participant = Participant.find(params[:id])
      @participant.destroy
      render json: { message: "Participant was successfully destroyed." }, status: :ok
    end

    def participant_assignment
        participant = Participant.find(params[:participant_id])
        assignment = participant.assignment
    
        render json: assignment, status: :ok
    rescue ActiveRecord::RecordNotFound
        render json: { error: "Participant not found" }, status: :not_found
    end
    
  
    private
  
    def participant_params
      params.require(:participant).permit(:user_id, :assignment_id, :type)
    end
  
  end
  