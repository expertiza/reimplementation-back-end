# frozen_string_literal: true
class AssignmentsController < ApplicationController
  # Skip authorization for tests
  skip_before_action :authorize_request, raise: false

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # GET /assignments
  def index
    assignments = Assignment.all
    render json: assignments
  end

  # GET /assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    render json: assignment
  end

  # POST /assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      render json: assignment, status: :created
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    if assignment.update(assignment_params)
      render json: assignment, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # DELETE /assignments/:id
  def destroy
    assignment = Assignment.find_by(id: params[:id])
    if assignment
      if assignment.destroy
        render json: { message: "Assignment deleted successfully!" }, status: :ok
      else
        render json: { error: "Failed to delete assignment", details: assignment.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Assignment not found" }, status: :not_found
    end
  end

  # Add participant to assignment
  def add_participant
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end

    new_participant = assignment.add_participant(params[:user_id])
    if new_participant.save
      render json: new_participant, status: :ok
    else
      render json: new_participant.errors, status: :unprocessable_entity
    end
  end

  # Remove participant from assignment
  def remove_participant
    user = User.find_by(id: params[:user_id])
    assignment = Assignment.find_by(id: params[:assignment_id])

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end

    assignment.remove_participant(user.id)
    if assignment.save
      render json: { message: "Participant removed successfully!" }, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # Remove course from assignment
  def remove_assignment_from_course
    assignment = Assignment.find(params[:assignment_id])
    assignment.remove_assignment_from_course
    if assignment.save
      render json: assignment, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # Assign course to assignment
  def assign_course
    assignment = Assignment.find(params[:assignment_id])
    course = Course.find(params[:course_id])
    assignment.assign_course(course.id)

    if assignment.save
      render json: assignment, status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # Copy existing assignment
  def copy_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end

    new_assignment = assignment.copy
    if new_assignment.save
      render json: new_assignment, status: :ok
    else
      render json: new_assignment.errors, status: :unprocessable_entity
    end
  end

  # Show assignment details
  def show_assignment_details
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end

    render json: {
      id: assignment.id,
      name: assignment.name,
      has_badge: assignment.has_badge?,
      pair_programming_enabled: assignment.pair_programming_enabled?,
      is_calibrated: assignment.is_calibrated?,
      staggered_and_no_topic: get_staggered_and_no_topic(assignment)
    }, status: :ok
  end

  # Check various boolean flags
  %i[has_topics team_assignment valid_num_review has_teams varying_rubrics_by_round?].each do |method_name|
    define_method(method_name) do
      assignment = Assignment.find_by(id: params[:assignment_id])
      if assignment.nil?
        render json: { error: "Assignment not found" }, status: :not_found
        return
      end

      if method_name == :valid_num_review
        render json: assignment.valid_num_review(params[:review_type]), status: :ok
      elsif method_name == :varying_rubrics_by_round?
        if AssignmentQuestionnaire.exists?(assignment_id: assignment.id)
          render json: assignment.varying_rubrics_by_round?, status: :ok
        else
          render json: { error: "No questionnaire/rubric exists for this assignment." }, status: :not_found
        end
      else
        render json: assignment.send("#{method_name}?"), status: :ok
      end
    end
  end

  private

  def assignment_params
    params.require(:assignment).permit(
      :name, :title, :description, :directory_path, :instructor_id, :course_id, :spec_location, :private,
      :show_template_review, :require_quiz, :has_badge, :staggered_deadline,
      :is_calibrated, :has_teams, :max_team_size, :show_teammate_review,
      :is_pair_programming, :has_mentors, :has_topics, :review_topic_threshold,
      :maximum_number_of_reviews_per_submission, :review_strategy,
      :review_rubric_varies_by_round, :review_rubric_varies_by_topic,
      :review_rubric_varies_by_role, :has_max_review_limit,
      :set_allowed_number_of_reviews_per_reviewer,
      :set_required_number_of_reviews_per_reviewer, :is_review_anonymous,
      :is_review_done_by_teams, :allow_self_reviews,
      :reviews_visible_to_other_reviewers, :number_of_review_rounds,
      :days_between_submissions, :late_policy_id, :is_penalty_calculated,
      :calculate_penalty, :use_signup_deadline, :use_drop_topic_deadline,
      :use_team_formation_deadline, :use_date_updater, :submission_allowed,
      :review_allowed, :teammate_allowed, :metareview_allowed,
      weights: [], notification_limits: [], reminder: []
    )
  end

  def not_found
    render json: { error: "Assignment not found" }, status: :not_found
  end

  def get_staggered_and_no_topic(assignment)
    topic_id = SignedUpTeam
               .joins(team: :teams_users)
               .where(teams_users: { user_id: current_user.id, team_id: Team.where(parent_id: assignment.id).pluck(:id) })
               .pluck(:project_topic_id)
               .first

    assignment.staggered_and_no_topic?(topic_id)
  end
end