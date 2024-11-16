class StudentTeamsController < ApplicationController
    
    # GET /student_teams
    def index
    end

    # GET /student_teams/:student_id
    def show
        @student = AssignmentParticipant.find(params[:student_id])
        render json: @student, status: :ok
    end

    # POST /student_teams/:student_id
    def create
    end
    
    # PATCH /student_teams/:team_id
    def update
    end

    # DELETE /student_teams/:team_id/:student_id
    def destroy
    end

end
  