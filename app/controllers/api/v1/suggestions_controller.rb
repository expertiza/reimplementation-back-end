class Api::V1::SuggestionsController < ApplicationController
  include PrivilegeHelper

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
    if PrivilegeHelper.current_user_has_ta_privileges?
      transaction do
        @suggestion = Suggestion.find(params[:id])
        @suggestion.update_attribute('status', 'Approved')
        create_topic_from_suggestion!
        unless @suggestion.user_id.nil?
          @suggester = User.find(@suggestion.user_id)
          sign_team_up_to_assignment_and_topic!
          send_notice_of_approval!
        end
        render json: @suggestion, status: :ok
      end
    else
      render json: { error: 'Students cannot approve a suggestion.' }, status: :forbidden
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
    if PrivilegeHelper.current_user_has_ta_privileges?
      Suggestion.find(params[:id]).destroy!
      render json: {}, status: :ok
    else
      render json: { error: 'Students do not have permission to delete suggestions.' }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: e, status: :unprocessable_entity
  end

  def index
    if PrivilegeHelper.current_user_has_ta_privileges?
      render json: Suggestion.where(assignment_id: params[:id]), status: :ok
    else
      render json: { error: 'Students do not have permission to view all suggestions.' }, status: :forbidden
    end
  end

  def reject
    if PrivilegeHelper.current_user_has_ta_privileges?
      suggestion = Suggestion.find(params[:id])
      if suggestion.status == 'Initialized'
        suggestion.update_attribute('status', 'Rejected')
        render json: suggestion, status: :ok
      else
        render json: { error: 'Suggestion has already been approved or rejected.' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Students cannot reject a suggestion.' }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: e, status: :not_found
  end

  def show
    @suggestion = Suggestion.find(params[:id])
    puts @suggestion.user_id
    puts @current_user.id
    if @suggestion.user_id == @current_user.id || PrivilegeHelper.current_user_has_ta_privileges?
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

  def create_topic_from_suggestion!
    @signuptopic = SignUpTopic.create!(
      topic_identifier: "S#{Suggestion.where(assignment_id: @suggestion.assignment_id).count}",
      topic_name: @suggestion.title,
      assignment_id: @suggestion.assignment_id,
      max_choosers: 1
    )
  end

  def send_notice_of_approval!
    Mailer.send_topic_approved_message(
      to: @suggester.email,
      cc: User.joins(:teams_users).where(teams_users: { team_id: @team.id }).where.not(id: @suggester.id).map(&:email),
      subject: "Suggested topic '#{@suggestion.title}' has been approved",
      body: {
        approved_topic_name: @suggestion.title,
        suggester: @suggester.name
      }
    )
  end

  def sign_team_up_to_assignment_and_topic!
    return unless @suggestion.auto_signup == true

    @team = Team.where(assignment_id: @signuptopic.assignment_id).joins(:teams_user)
                .where(teams_user: { user_id: @suggester.id }).first
    if @team.nil?
      @team = Team.create!(assignment_id: @signuptopic.assignment_id)
      TeamsUser.create!(team_id: @team.id, user_id: @suggester.id)
    end
    if SignedUpTeam.exists?(sign_up_topic_id: @signuptopic.id, team_id: @team.id, is_waitlisted: false)
      SignedUpTeam.where(team_id: @team.id, is_waitlisted: 1).destroy_all
      SignedUpTeam.create!(sign_up_topic_id: @signuptopic.id, team_id: @team.id, is_waitlisted: false)
    end
    @signuptopic.update_attribute(:private_to, @suggester.id)
  end
end
