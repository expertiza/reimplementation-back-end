module Api
  module V1
    class TeamsController < ApplicationController
      # Set the @team instance variable before executing actions except index and create
      before_action :set_team, except: [:index, :create]

      # Validate team type only during team creation
      before_action :validate_team_type, only: [:create]

      # GET /api/v1/teams
      # Fetches all teams and renders them using TeamSerializer
      def index
        @teams = Team.all
        render json: @teams, each_serializer: TeamSerializer
      end

      # GET /api/v1/teams/:id
      # Shows a specific team based on ID
      def show
        render json: @team, serializer: TeamSerializer
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
      end

      # POST /api/v1/teams
      # Creates a new team associated with the current user
      def create
        @team = Team.new(team_params)
        @team.user = current_user
        if @team.save
          render json: @team, serializer: TeamSerializer, status: :created
        else
          render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/teams/:id/members
      # Lists all members of a specific team
      def members
        render json: @team.team_members, each_serializer: TeamMemberSerializer
      end

      # POST /api/v1/teams/:id/members
      # Adds a new member to the team unless it's already full
      def add_member
        return render json: { errors: ['Team is full'] }, status: :unprocessable_entity if @team.full?

        user = User.find(team_member_params[:user_id])
        team_member = @team.team_members.build(user: user)
        
        if team_member.save
          render json: team_member, serializer: TeamMemberSerializer, status: :created
        else
          render json: { errors: team_member.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end

      # DELETE /api/v1/teams/:id/members/:user_id
      # Removes a member from the team based on user ID
      def remove_member
        team_member = @team.team_members.find_by(user_id: params[:user_id])
        if team_member
          team_member.destroy
          head :no_content
        else
          render json: { error: 'Member not found' }, status: :not_found
        end
      end

      # GET /api/v1/teams/:id/join_requests
      # Lists all join requests for the team
      def join_requests
        render json: @team.team_join_requests, each_serializer: TeamJoinRequestSerializer
      end

      # POST /api/v1/teams/:id/join_requests
      # Creates a new join request for a team
      def create_join_request
        join_request = @team.team_join_requests.build(team_join_request_params)
        if join_request.save
          render json: join_request, serializer: TeamJoinRequestSerializer, status: :created
        else
          render json: { errors: join_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/teams/:id/join_requests/:id
      # Updates the status or details of a specific join request
      def update_join_request
        join_request = @team.team_join_requests.find(params[:join_request_id])
        if join_request.update(team_join_request_params)
          render json: join_request, serializer: TeamJoinRequestSerializer
        else
          render json: { errors: join_request.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Join request not found' }, status: :not_found
      end

      private

      # Finds the team by ID and assigns to @team, else renders not found
      def set_team
        @team = Team.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
      end

      # Whitelists the parameters allowed for team creation/updation
      def team_params
        params.require(:team).permit(:name, :max_team_size, :type, :assignment_id)
      end

      # Whitelists parameters required to add a team member
      def team_member_params
        params.require(:team_member).permit(:user_id)
      end

      # Whitelists parameters required to create or update join request
      def team_join_request_params
        params.require(:team_join_request).permit(:user_id, :status)
      end

      # Validates the team type before team creation to ensure it's among allowed types
      def validate_team_type
        return unless params[:team] && params[:team][:type]
        valid_types = ['CourseTeam', 'AssignmentTeam', 'MentoredTeam']
        unless valid_types.include?(params[:team][:type])
          render json: { error: 'Invalid team type' }, status: :unprocessable_entity
        end
      end

      # Placeholder method to get current user (can be replaced by actual auth logic)
      def current_user
        @current_user
      end
    end
  end
end 