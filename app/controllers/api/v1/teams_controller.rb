module Api
  module V1
    class TeamsController < ApplicationController
      before_action :set_team, except: [:index, :create]
      before_action :validate_team_type, only: [:create]

      # GET /api/v1/teams
      def index
        @teams = Team.all
        render json: @teams, each_serializer: TeamSerializer
      end

      # GET /api/v1/teams/:id
      def show
        render json: @team, serializer: TeamSerializer
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
      end

      # POST /api/v1/teams
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
      def members
        render json: @team.team_members, each_serializer: TeamMemberSerializer
      end

      # POST /api/v1/teams/:id/members
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
      def join_requests
        render json: @team.team_join_requests, each_serializer: TeamJoinRequestSerializer
      end

      # POST /api/v1/teams/:id/join_requests
      def create_join_request
        join_request = @team.team_join_requests.build(team_join_request_params)
        if join_request.save
          render json: join_request, serializer: TeamJoinRequestSerializer, status: :created
        else
          render json: { errors: join_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/teams/:id/join_requests/:id
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

      def set_team
        @team = Team.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
      end

      def team_params
        params.require(:team).permit(:name, :max_team_size, :type, :assignment_id)
      end

      def team_member_params
        params.require(:team_member).permit(:user_id)
      end

      def team_join_request_params
        params.require(:team_join_request).permit(:user_id, :status)
      end

      def validate_team_type
        return unless params[:team] && params[:team][:type]
        valid_types = ['CourseTeam', 'AssignmentTeam', 'MentoredTeam']
        unless valid_types.include?(params[:team][:type])
          render json: { error: 'Invalid team type' }, status: :unprocessable_entity
        end
      end

      def current_user
        @current_user
      end
    end
  end
end 