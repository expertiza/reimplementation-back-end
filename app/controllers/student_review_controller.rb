class StudentReviewController < ApplicationController
  before_action :set_assignment_and_participant

  def action_allowed?
    current_user_has_student_privileges?
  end

  # GET /assignments/:assignment_id/student_review/list
  def list
    reviewer_id = reviewer_id_for(@participant)
    mappings    = ReviewResponseMap
                  .where(reviewer_id: reviewer_id, reviewed_object_id: @assignment.id)
                  .includes(:responses, :reviewee)
    # Shuffle calibration reviews so they appear at unpredictable positions
    # in the list, preventing students from identifying them by position.
    mappings = mappings.sort_by { rand } if @assignment.is_calibrated?
    review_list = mappings.map { |map| serialize_mapping(map) }
    completed   = review_list.count { |r| r[:status] == 'completed' }
    in_progress = review_list.count { |r| r[:status] == 'in_progress' }

    render json: {
      assignment_id: @assignment.id,
      assignment_name: @assignment.name,
      is_calibrated: @assignment.is_calibrated?,
      is_dynamic: @assignment.review_assignment_strategy == 'Auto-Selected',
      topics_assigned_by_bidding: @assignment.topics_assigned_by_bidding,
      can_choose_topic_to_review: @assignment.can_choose_topic_to_review,
      num_reviews_total: review_list.size,
      num_reviews_completed: completed,
      num_reviews_in_progress: in_progress,
      reviews: review_list
    }
  end

  # GET /assignments/:assignment_id/student_review/:mapping_id/form
  def form
    mapping = ReviewResponseMap.find_by(id: params[:mapping_id], reviewed_object_id: @assignment.id)
    unless mapping
      return render json: { error: 'No review found with that ID for this assignment.' },
                    status: :not_found
    end
    unless reviewer_for?(mapping)
      return render json: { error: 'You are not the author of this review.' }, status: :forbidden
    end

    reviewee        = mapping.reviewee
    latest_response = mapping.responses.includes(:scores).max_by(&:id)
    topic           = reviewee.is_a?(AssignmentTeam) ? SignedUpTeam.find_by(team_id: reviewee.id)&.project_topic : nil

    render json: {
      assignment_id: @assignment.id,
      assignment_name: @assignment.name,
      mapping_id: mapping.id,
      reviewee_team_name: reviewee.try(:name),
      topic_name: topic&.topic_name,
      questionnaire: build_questionnaire_data(@assignment),
      response: serialize_response(latest_response)
    }
  end

  private

  def reviewer_for?(mapping)
    mapping.reviewer_id == @participant.id || team_reviewer?(mapping)
  end

  def team_reviewer?(mapping)
    mapping.reviewer.is_a?(AssignmentTeam) &&
      mapping.reviewer.participants.exists?(user_id: current_user.id)
  end

  def build_questionnaire_data(assignment)
    current_round = DueDate.current_round_number_for(assignment)
    aq = assignment.assignment_questionnaires.find_by(used_in_round: current_round) if current_round.positive?
    aq ||= assignment.assignment_questionnaires.find_by(used_in_round: nil)
    aq ||= assignment.assignment_questionnaires.first
    q = aq&.questionnaire
    return nil unless q

    {
      id: q.id,
      name: q.name,
      min_item_score: q.min_question_score,
      max_item_score: q.max_question_score,
      items: q.items.order(:seq).map do |item|
        { id: item.id, txt: item.txt, question_type: item.question_type,
          weight: item.weight, seq: item.seq }
      end
    }
  end

  def serialize_response(response)
    return nil unless response

    {
      id: response.id,
      is_submitted: response.is_submitted,
      additional_comment: response.additional_comment,
      answers: response.scores.map do |a|
        { id: a.id, item_id: a.item_id, answer: a.answer, comments: a.comments }
      end
    }
  end

  def set_assignment_and_participant
    @assignment  = Assignment.find(params[:assignment_id])
    @participant = AssignmentParticipant.find_by(parent_id: @assignment.id, user_id: current_user.id)
    render json: { error: 'You are not a participant in this assignment.' }, status: :forbidden unless @participant
  end

  def reviewer_id_for(participant)
    @assignment.is_review_done_by_teams ? participant.team&.id || participant.id : participant.id
  end

  def review_status(map)
    last_response = map.responses.max_by(&:id)
    return 'not_started' unless last_response

    last_response.is_submitted ? 'completed' : 'in_progress'
  end

  def serialize_mapping(map)
    topic = SignedUpTeam.find_by(team_id: map.reviewee&.id)&.project_topic

    {
      mapping_id: map.id,
      reviewee_team_id: map.reviewee&.id,
      reviewee_team_name: map.reviewee&.name,
      topic_id: topic&.id,
      topic_name: topic&.topic_name,
      status: review_status(map),
      submission_updated: map.has_submission_been_updated?,
      for_calibration: map.for_calibration
    }
  end
end
