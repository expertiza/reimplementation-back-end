class Api::V1::SuggestionsController < ApplicationController
  include AuthorizationHelper

  def add_comment
    render json: SuggestionComment.create!(
      comment: params[:comment],
      suggestion_id: params[:id],
      user_id: @current_user.id
    ), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: e.record.errors, status: :unprocessable_entity
  end

  def approve
    deny_student('Students cannot approve a suggestion.')
    transaction do
      @suggestion = Suggestion.find(params[:id])
      @suggestion.update_attribute('status', 'Approved')
      create_topic_from_suggestion!
      unless @suggestion.user_id.nil?
        @suggester = User.find(@suggestion.user_id)
        sign_team_up
        send_notice_of_approval!
      end
      render json: @suggestion, status: :ok
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: e.record.errors, status: :unprocessable_entity
  end

  def create
    render json: Suggestion.create!(
      title: params[:title],
      description: params[:description],
      status: 'Initialized',
      auto_signup: params[:auto_signup],
      assignment_id: params[:assignment_id],
      user_id: params[:suggestion_anonymous] ? nil : @current_user.id
    ), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: e.record.errors, status: :unprocessable_entity
  end

  def destroy
    deny_student('Students cannot delete suggestions.')
    Suggestion.find(params[:id]).destroy!
    render json: {}, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: e, status: :unprocessable_entity
  end

  def index
    deny_student('Students cannot view all suggestions.')
    render json: Suggestion.where(assignment_id: params[:id]), status: :ok
  end

  def reject
    deny_student('Students cannot reject a suggestion.')
    suggestion = Suggestion.find(params[:id])
    if suggestion.status == 'Initialized'
      suggestion.update_attribute('status', 'Rejected')
      render json: suggestion, status: :ok
    else
      render json: { error: 'Suggestion has already been approved or rejected.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  end

  def show
    @suggestion = Suggestion.find(params[:id])
    puts @suggestion.user_id
    puts @current_user.id
    if @suggestion.user_id == @current_user.id || AuthorizationHelper.current_user_has_ta_privileges?
      render json: {
        suggestion: @suggestion,
        comments: SuggestionComment.where(suggestion_id: params[:id])
      }, status: :ok
    else
      render json: { error: 'Students can only view their own suggestions.' }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  end

  private

  def deny_student(err_msg)
    render json: { error: err_msg }, status: :forbidden unless AuthorizationHelper.current_user_has_ta_privileges?
  end

  def create_topic_from_suggestion!
    @signuptopic = SignUpTopic.create!(
      topic_identifier: "S#{Suggestion.where(assignment_id: @suggestion.assignment_id).count}",
      topic_name: @suggestion.title,
      assignment_id: @suggestion.assignment_id,
      max_choosers: 1
    )
  end

  def send_notice_of_approval!
    Mailer.send_topic_approved_email(
      cc: User.joins(:teams_users).where(teams_users: { team_id: @team.id }).where.not(id: @suggester.id).map(&:email),
      subject: "Suggested topic '#{@suggestion.title}' has been approved",
      suggester: @suggester,
      topic_name: @suggestion.title
    )
  end

  def sign_team_up!
    return unless @suggestion.auto_signup == true

    @team = Team.where(assignment_id: @signuptopic.assignment_id).joins(:teams_user)
                .where(teams_user: { user_id: @suggester.id }).first
    if @team.nil?
      @team = Team.create!(assignment_id: @signuptopic.assignment_id)
      TeamsUser.create!(team_id: @team.id, user_id: @suggester.id)
    end
    unless SignedUpTeam.exists?(team_id: @team.id, is_waitlisted: false)
      SignedUpTeam.where(team_id: @team.id, is_waitlisted: true).destroy_all
      SignedUpTeam.create!(sign_up_topic_id: @signuptopic.id, team_id: @team.id, is_waitlisted: false)
    end
    @signuptopic.update_attribute(:private_to, @suggester.id)
  end
end
