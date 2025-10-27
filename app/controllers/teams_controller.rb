# frozen_string_literal: true

class TeamsController < ApplicationController
  # Set the @team instance variable before executing actions except index and create
  before_action :set_team, except: [:index, :create]

  # GET /teams
  # Fetches all teams and renders them using TeamSerializer
  def index
    @teams = Team.all.includes(teams_participants: :user)
    render json: @teams, each_serializer: TeamSerializer
  end

  # GET /teams/:id
  # Shows a specific team based on ID
  def show
    render json: @team, serializer: TeamSerializer
  end

  # POST /teams
  # Creates a new team associated with the current user
  def create
    # Extract the team type and parameters
    team_type_str = team_params[:type]
    safe_params = team_params.except(:type)

    # 1. Whitelist the team type to prevent STI-related crashes
    # We explicitly check for allowed types rather than passing untrusted input to .new
    team_class = case team_type_str
                 when 'AssignmentTeam' then AssignmentTeam
                 when 'CourseTeam' then CourseTeam
                 when 'MentoredTeam' then MentoredTeam
                 end

    unless team_class
      # Return 422 if the type is invalid or missing
      render json: { errors: ["Invalid or missing team type: '#{team_type_str}'"] },
             status: :unprocessable_entity
      return
    end

    # 2. Instantiate the correct team subclass using the safe params
    @team = team_class.new(safe_params)

    # 4. Save and render
    if @team.save
      render json: @team, serializer: TeamSerializer, status: :created
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /teams/:id/members
  # Lists all members of a specific team
  def members
    participants = @team.participants.includes(:user)
    render json: participants.map(&:user), each_serializer: UserSerializer
  end

  # POST /teams/:id/members
  # Adds a new member to the team.
  def add_member
    # Find the user specified in the request.
    user = User.find(team_participant_params[:user_id])

    # Use polymorphic participant_class method instead of type checking
    participant = @team.participant_class.find_by(
      user_id: user.id,
      parent_id: @team.parent_entity.id
    )

    unless participant
      return render json: {
        errors: ["#{user.name} is not a participant in this #{@team.context_label}."]
      }, status: :unprocessable_entity
    end

    # Delegate the add operation to the Team model with the found participant.
    result = @team.add_member(participant)

    if result[:success]
      render json: user, serializer: UserSerializer, status: :created
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'User not found' }, status: :not_found
  end

  # DELETE /teams/:id/members/:user_id
  # Removes a member from the team based on user ID
  def remove_member
    user = User.find(params[:user_id])
    participant = @team.participant_class.find_by(user_id: user.id, parent_id: @team.parent_entity.id)
    tp = @team.teams_participants.find_by(participant: participant)

    if tp
      tp.destroy
      head :no_content
    else
      render json: { error: 'Member not found' }, status: :not_found
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
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
    params.require(:team).permit(:name, :type, :parent_id)
  end

  # Whitelists parameters required to add a team member
  def team_participant_params
    params.require(:team_participant).permit(:user_id)
  end
end
