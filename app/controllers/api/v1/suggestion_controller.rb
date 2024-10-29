class SuggestionController < ApplicationController
  before_action :set_suggestion, only: %i[add_comment approve reject show update]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify method: :post, only: %i[create update], redirect_to: { action: :index }

  def add_comment
    if SuggestionComment.new(commenter: session[:user].name, comments: params[:suggestion_comment][:comments],
                             suggestion_id: params[:id], vote: params[:suggestion_comment][:vote]).save
      flash[:notice] = 'Your comment has been successfully added.'
    else
      flash[:error] = 'There was an error in adding your comment.'
    end
    redirect_to action: 'show', id: @suggestion.id
  end

  def approve
    @signuptopic = SignUpTopic.new_topic_from_suggestion(@suggestion)
    @suggester = User.find_by(name: @suggestion.unityID)&.id
    if @signuptopic != 'failed' && @suggester
      approval_process if @suggestion.signup_preference == 'Y'
      notice_of_approval
      flash[:success] = 'The suggestion was successfully approved.'
    else
      flash[:error] = 'An error occurred when approving the suggestion.'
    end
    redirect_to action: 'show', id: @suggestion.id
  end

  def create
    @assignment = Assignment.find(session[:assignment_id])
    @suggestion = Suggestion.new(assignment_id: session[:assignment_id], description: params[:description],
                                 signup_preference: params[:signup_preference], status: 'Initialized',
                                 title: params[:title], unityID: params[:suggestion_anonymous] ? '' : params[:unityID])

    if @suggestion.save
      flash[:success] =
        if @suggestion.unityID.empty?
          'You have submitted an anonymous suggestion. It will not show in the suggested topic table below.'
        else
          'Thank you for your suggestion!'
        end
      redirect_to action: 'show', id: @suggestion.id
    else
      redirect_to action: :new, id: session[:assignment_id]
    end
  end

  def index
    @suggestions = Suggestion.where(assignment_id: params[:id])
    @assignment = Assignment.find(params[:id])
    redirect_to @assignment unless current_user_has_ta_privileges?
  end

  def new
    session[:assignment_id] = params[:id]
    @suggestion = Suggestion.new
    @suggestions = Suggestion.where(unityID: session[:user].name, assignment_id: params[:id])
    @assignment = Assignment.find(params[:id])
  end

  def reject
    if @suggestion.update_attribute('status', 'Rejected')
      flash[:notice] = 'The suggestion has been successfully rejected.'
    else
      flash[:error] = 'An error occurred when rejecting the suggestion.'
    end
    redirect_to action: 'show', id: @suggestion.id
  end

  def show; end

  def update
    @suggestion.update_attributes(title: params[:suggestion][:title], description: params[:suggestion][:description],
                                  signup_preference: params[:suggestion][:signup_preference])
    redirect_to action: 'show', id: @suggestion.id
  end

  private

  def approval_process
    @team_id = TeamsUser.team_id(@suggestion.assignment_id, @suggester)
    @topic_id = SignedUpTeam.topic_id(@suggestion.assignment_id, @suggester)

    if @team_id.nil?
      AssignmentTeam.create(name: "Team_#{rand(10_000)}", parent_id: @signuptopic.assignment_id, type: 'AssignmentTeam')
                    .create_new_team(@suggester, @signuptopic)
    elsif @topic_id.nil?
      SignedUpTeam.where(team_id: @team_id, is_waitlisted: 1).destroy_all
      SignedUpTeam.create(team_id: @team_id, topic_id: @signuptopic.id, is_waitlisted: 0)
    else
      @signuptopic.private_to = @suggester
      @signuptopic.save
    end
  end

  def notice_of_approval
    Mailer.suggested_topic_approved_message(
      to: @suggester.email,
      cc: User.joins(:teams).where(teams: { id: @team_id }).where.not(id: @suggester.id).map(&:email),
      subject: "Suggested topic '#{@suggestion.title}' has been approved",
      body: {
        approved_topic_name: @suggestion.title,
        suggester: @suggester.name
      }
    ).deliver_now!
  end

  def set_suggestion
    @suggestion = Suggestion.find(params[:id])
  end

  def suggestion_params
    params.require(:suggestion).permit(:assignment_id, :title, :description, :status, :unityID, :signup_preference)
  end
end
