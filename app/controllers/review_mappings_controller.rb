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
      assignment_id: @assignment.id,
      calibration_participants: calibration_participant_rows
    }, status: :ok
  end

  # POST /assignments/:assignment_id/review_mappings/calibration_participants
  # Body: { username: "unctlt1" }
  def add_calibration_participant
    username = (params[:username] || params.dig(:calibration_participant, :username)).to_s.strip
    return render json: { error: 'username is required' }, status: :bad_request if username.blank?

    user = User.find_by(name: username) || User.find_by(email: username)
    return render json: { error: "User '#{username}' not found" }, status: :not_found unless user

    instructor_participant = find_or_create_instructor_participant
    return render json: { error: 'Assignment has no instructor' }, status: :unprocessable_entity unless instructor_participant

    participant = nil
    team = nil
    map = nil

    ActiveRecord::Base.transaction do
      participant = AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: user.id) ||
                    @assignment.add_participant(user.id)

      team = participant.team || Team.create_team_for_participant(participant)

      map = ReviewResponseMap.find_or_create_by!(
        reviewer_id: instructor_participant.id,
        reviewee_id: team.id,
        reviewed_object_id: @assignment.id,
        for_calibration: true
      )
    end

    render json: serialize_calibration_row(participant, team, map), status: :created
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /assignments/:assignment_id/review_mappings/calibration_participants/:participant_id
  def remove_calibration_participant
    participant = AssignmentParticipant.find_by(id: params[:participant_id], parent_id: @assignment.id)
    return render json: { error: 'Calibration participant not found' }, status: :not_found unless participant

    team = participant.team
    return render json: { error: 'Participant has no team' }, status: :unprocessable_entity unless team

    ReviewResponseMap.where(
      reviewed_object_id: @assignment.id,
      reviewee_id: team.id,
      for_calibration: true
    ).destroy_all

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

  # ----- Helpers for the calibration participants endpoints -----

  # The instructor is the reviewer on every calibration ReviewResponseMap it
  # creates, so the instructor must also be registered as an
  # AssignmentParticipant on this assignment. Create that record lazily.
  def find_or_create_instructor_participant
    instructor = @assignment.instructor
    return nil unless instructor

    AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: instructor.id) ||
      @assignment.add_participant(instructor.id)
  end

  # Build one row per calibration submitter. A submitter is identified as the
  # (sole) member of a team that is the reviewee of any for_calibration map on
  # this assignment. Prefer the instructor's map as the "Begin" target.
  def calibration_participant_rows
    maps = ReviewResponseMap.where(
      reviewed_object_id: @assignment.id,
      for_calibration: true
    ).order(:id)

    instructor_user_id = @assignment.instructor_id
    maps_by_team = maps.group_by(&:reviewee_id)

    maps_by_team.map do |team_id, team_maps|
      team = AssignmentTeam.find_by(id: team_id)
      next nil unless team

      instructor_map = team_maps.find { |m| m.reviewer&.user_id == instructor_user_id } || team_maps.first
      submitter = team.participants.where(type: 'AssignmentParticipant').first
      next nil unless submitter

      serialize_calibration_row(submitter, team, instructor_map)
    end.compact
  end

  def serialize_calibration_row(participant, team, instructor_map)
    {
      participant_id: participant.id,
      user_id: participant.user_id,
      username: participant.user&.name,
      full_name: participant.user&.full_name,
      handle: participant.handle,
      team_id: team&.id,
      team_name: team&.name,
      instructor_review_map_id: instructor_map&.id,
      submissions: team.respond_to?(:submitted_content_detail) ? team.submitted_content_detail : { hyperlinks: [], files: [] }
    }
  end
end
