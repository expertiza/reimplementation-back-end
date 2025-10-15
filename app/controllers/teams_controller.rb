class TeamsController < ApplicationController
  # Set the @team instance variable before executing actions except index and create
  before_action :set_team, except: [:index, :create]

  # Validate team type only during team creation
  before_action :validate_team_type, only: [:create]

  # GET /teams
  # Fetches all teams and renders them using TeamSerializer
  def index
    @teams = Team.all
    render json: @teams, each_serializer: TeamSerializer
  end

  # GET /teams/:id
  # Shows a specific team based on ID
  def show
    render json: @team, serializer: TeamSerializer
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Team not found' }, status: :not_found
  end

  # POST /teams
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

    # Determine the correct type of participant (Assignment or Course) based on the team type.
    participant_class = @team.is_a?(AssignmentTeam) ? AssignmentParticipant : CourseParticipant
    
    # Find the specific participant record for this user in the team's context.
    participant = participant_class.find_by(user_id: user.id, parent_id: @team.parent_id)

    # If no participant record exists, the user isn't part of the assignment/course.
    unless participant
      return render json: { errors: ["#{user.name} is not a participant in this context."] }, status: :unprocessable_entity
    end

    # Delegate the add operation to the Team model with the found participant.
    result = @team.add_member(participant)

    if result[:success]
      render json: user, serializer: UserSerializer, status: :created
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  end

  # DELETE /teams/:id/members/:user_id
  # Removes a member from the team based on user ID
  def remove_member
    user = User.find(params[:user_id])
    participant = Participant.find_by(user: user, parent_id: @team.parent_id)
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

  # Placeholder method to get current user (can be replaced by actual auth logic)
  def current_user
    @current_user
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
  def team_participant_params
    params.require(:team_participant).permit(:user_id)
  end

  # Validates the team type before team creation to ensure it's among allowed types
  def validate_team_type
    return unless params[:team] && params[:team][:type]
    valid_types = ['CourseTeam', 'AssignmentTeam', 'MentoredTeam']
    unless valid_types.include?(params[:team][:type])
      render json: { error: 'Invalid team type' }, status: :unprocessable_entity
    end
  end
end 
