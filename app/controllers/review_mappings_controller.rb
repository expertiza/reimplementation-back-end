class ReviewMappingsController < ApplicationController
  include Authorization
  before_action :set_assignment
  before_action :authorize

  # ===== STATIC ASSIGNMENT =====
  def assign_round_robin
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_statically(ReviewMappingStrategies::RoundRobinStrategy)
    render json: { status: "ok", message: "Round-robin assignments created" }
  end

  def assign_from_csv
    csv_text = params[:csv].read # file upload
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_from_csv(csv_text)
    render json: { status: "ok", message: "CSV-based assignments created" }
  end

    # POST /assignments/:assignment_id/review_mappings/random
    def assign_random
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_random
    render json: { status: "ok", message: "Random assignments created" }
    end


  # ===== DYNAMIC ASSIGNMENT =====
  def request_review_fewest
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamically(
      ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
      reviewer
    )

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No team available or limit reached" }, status: :unprocessable_entity
    end
  end

  def request_review_topic_balance
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamic_topic_fairly(reviewer, k: params[:k].to_i)

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No eligible topic/team available" }, status: :unprocessable_entity
    end
  end

  # ===== CALIBRATION =====
  def assign_calibration_artifacts
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_calibration_reviews_round_robin
    render json: { status: "ok", message: "Calibration reviews assigned to all reviewers" }
  end

  # ===== CALIBRATION PARTICIPANTS =====
  # The "Calibration" tab on the assignment edit view designates one or more
  # users as calibration submitters. The instructor types a username into the
  # text box and that user is added as an AssignmentParticipant, a team is
  # created for them (so submissions flow through the normal team-based
  # infrastructure), and a ReviewResponseMap with for_calibration = true is
  # created with the instructor as reviewer. The instructor later opens the
  # calibration report for this map to enter/compare the calibration review.

  # GET /assignments/:assignment_id/review_mappings/calibration_participants
  def list_calibration_participants
    render json: {
      assignment_id:            @assignment.id,
      calibration_participants: @assignment.calibration_participant_rows
    }, status: :ok
  end

  # POST /assignments/:assignment_id/review_mappings/calibration_participants
  # Body: { username: "unctlt1" }
  def add_calibration_participant
    username = (params[:username] || params.dig(:calibration_participant, :username)).to_s.strip
    return render json: { error: 'username is required' }, status: :bad_request if username.blank?

    user = User.find_by(name: username) || User.find_by(email: username)
    return render json: { error: "User '#{username}' not found" }, status: :not_found unless user

    row = @assignment.add_calibration_submitter!(user)
    render json: row, status: :created
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # NOTE: The demo-only "mock instructor response" endpoint that used to live
  # here has moved to Demo::CalibrationInstructorResponsesController so this
  # controller stays focused on real review-mapping behaviour. See
  # Demo::CalibrationInstructorSeeder for the demo's removal checklist.

  # DELETE /assignments/:assignment_id/review_mappings/calibration_participants/:participant_id
  def remove_calibration_participant
    participant = AssignmentParticipant.find_by(id: params[:participant_id], parent_id: @assignment.id)
    return render json: { error: 'Calibration participant not found' }, status: :not_found unless participant

    team = AssignmentTeam.team(participant)
    return render json: { error: 'Participant has no team' }, status: :unprocessable_entity unless team

    ReviewResponseMap.calibration_for(@assignment).where(reviewee_id: team.id).destroy_all

    render json: { message: "Calibration participant #{participant.id} removed." }, status: :ok
  end

  # ===== DELETE =====
  def destroy
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_review_mapping(params[:id])
    render json: { status: "ok", message: "Mapping deleted" }
  end

  def delete_all_for_reviewer
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_all_reviews_for(reviewer)
    render json: { status: "ok", message: "All mappings for reviewer deleted" }
  end

  # ===== INSTRUCTOR GRADING =====
  def grade_review
    mapping = ReviewResponseMap.find(params[:mapping_id])
    handler = ReviewMappingHandler.new(@assignment)

    handler.grade_review(mapping, grade: params[:grade], comment: params[:comment])
    render json: { status: "ok", message: "Review graded" }
  end

  # Actions that designate calibration submitters require teaching staff
  # privileges; everything else defaults to allowed and relies on
  # ApplicationController's own checks. We reuse the shared
  # `current_user_teaching_staff_of_assignment?` helper from the Authorization
  # concern instead of duplicating the logic here.
  CALIBRATION_PARTICIPANT_ACTIONS = %w[
    list_calibration_participants
    add_calibration_participant
    remove_calibration_participant
  ].freeze

  def action_allowed?
    return current_user_teaching_staff_of_assignment?(params[:assignment_id]) if CALIBRATION_PARTICIPANT_ACTIONS.include?(params[:action])

    true
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end
end
