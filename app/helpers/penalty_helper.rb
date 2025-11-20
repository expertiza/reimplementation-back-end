module PenaltyHelper
  def get_penalty(participant_id)
    set_participant_and_assignment(participant_id)
    set_late_policy if @assignment.late_policy_id
  
    penalties = { submission: 0, review: 0, meta_review: 0 }
    penalties[:submission] = calculate_submission_penalty
    penalties[:review] = calculate_review_penalty
    penalties[:meta_review] = calculate_meta_review_penalty
    penalties
  end
    
  def set_participant_and_assignment(participant_id)
    @participant = AssignmentParticipant.find(participant_id)
    @assignment = @participant.assignment
  end
  
  def set_late_policy
    late_policy = LatePolicy.find(@assignment.late_policy_id)
    @penalty_per_unit = late_policy.penalty_per_unit
    @max_penalty_for_no_submission = late_policy.max_penalty
    @penalty_unit = late_policy.penalty_unit
  end

  def calculate_submission_penalty
    return 0 if @penalty_per_unit.nil?
  
    submission_due_date = get_submission_due_date
    submission_records = SubmissionRecord.where(team_id: @participant.team.id, assignment_id: @participant.assignment.id)
    late_submission_times = get_late_submission_times(submission_records, submission_due_date)
  
    if late_submission_times.any?
      calculate_late_submission_penalty(late_submission_times.last.updated_at, submission_due_date)
    else
      handle_no_submission(submission_records)
    end
  end
  
  def get_submission_due_date
    AssignmentDueDate.where(deadline_type_id: @submission_deadline_type_id, parent_id: @assignment.id).first.due_at
  end
  
  def get_late_submission_times(submission_records, submission_due_date)
    submission_records.select { |submission_record| submission_record.updated_at > submission_due_date }
  end
  
  def calculate_late_submission_penalty(last_submission_time, submission_due_date)
    return 0 if last_submission_time <= submission_due_date
  
    time_difference = last_submission_time - submission_due_date
    penalty_units = calculate_penalty_units(time_difference, @penalty_unit)
    penalty_for_submission = penalty_units * @penalty_per_unit
    apply_max_penalty_limit(penalty_for_submission)
  end
  
  def handle_no_submission(submission_records)
    submission_records.any? ? 0 : @max_penalty_for_no_submission
  end
  
  def apply_max_penalty_limit(penalty_for_submission)
    if penalty_for_submission > @max_penalty_for_no_submission
      @max_penalty_for_no_submission
    else
      penalty_for_submission
    end
  end

  def calculate_review_penalty
    calculate_penalty(@assignment.num_reviews, @review_deadline_type_id, ReviewResponseMap, :get_reviewer)
  end
  
  def calculate_meta_review_penalty
    calculate_penalty(@assignment.num_review_of_reviews, @meta_review_deadline_type_id, MetareviewResponseMap, :id)
  end
  
  private
  
  def calculate_penalty(num_reviews_required, deadline_type_id, mapping_class, reviewer_method)
    return 0 if num_reviews_required <= 0 || @penalty_per_unit.nil?
  
    review_mappings = mapping_class.where(reviewer_id: @participant.send(reviewer_method).id)
    review_due_date = AssignmentDueDate.where(deadline_type_id: deadline_type_id, parent_id: @assignment.id).first
    return 0 if review_due_date.nil?
  
    compute_penalty_on_reviews(review_mappings, review_due_date.due_at, num_reviews_required)
  end

  def compute_penalty_on_reviews(review_mappings, review_due_date, num_of_reviews_required, penalty_unit, penalty_per_unit, max_penalty)
    review_timestamps = collect_review_timestamps(review_mappings)
    review_timestamps.sort!
    
    penalty = 0
  
    num_of_reviews_required.times do |i|
      if review_timestamps[i]
        penalty += calculate_review_penalty(review_timestamps[i], review_due_date, penalty_unit, penalty_per_unit, max_penalty)
      else
        penalty = apply_max_penalty_if_missing(max_penalty)
      end
    end
  
    penalty
  end
  
  private
  
  def collect_review_timestamps(review_mappings)
    review_mappings.filter_map do |map|
      Response.find_by(map_id: map.id)&.created_at unless map.response.empty?
    end
  end
  
  def calculate_review_penalty(submission_date, due_date, penalty_unit, penalty_per_unit, max_penalty)
    return 0 if submission_date <= due_date
  
    time_difference = submission_date - due_date
    penalty_units = calculate_penalty_units(time_difference, penalty_unit)
    [penalty_units * penalty_per_unit, max_penalty].min
  end
  
  def apply_max_penalty_if_missing(max_penalty)
    max_penalty
  end

  def calculate_penalty_units(time_difference, penalty_unit)
    case penalty_unit
    when 'Minute'
      time_difference / 60
    when 'Hour'
      time_difference / 3600
    when 'Day'
      time_difference / 86_400
    end
  end
end
module PenaltyHelper
  def get_penalty(participant_id)
    set_participant_and_assignment(participant_id)
    set_late_policy if @assignment.late_policy_id
  
    penalties = { submission: 0, review: 0, meta_review: 0 }
    penalties[:submission] = calculate_submission_penalty
    penalties[:review] = calculate_review_penalty
    penalties[:meta_review] = calculate_meta_review_penalty
    penalties
  end
    
  def set_participant_and_assignment(participant_id)
    @participant = AssignmentParticipant.find(participant_id)
    @assignment = @participant.assignment
  end
  
  def set_late_policy
    late_policy = LatePolicy.find(@assignment.late_policy_id)
    @penalty_per_unit = late_policy.penalty_per_unit
    @max_penalty_for_no_submission = late_policy.max_penalty
    @penalty_unit = late_policy.penalty_unit
  end

  def calculate_submission_penalty
    return 0 if @penalty_per_unit.nil?
  
    submission_due_date = get_submission_due_date
    submission_records = SubmissionRecord.where(team_id: @participant.team.id, assignment_id: @participant.assignment.id)
    late_submission_times = get_late_submission_times(submission_records, submission_due_date)
  
    if late_submission_times.any?
      calculate_late_submission_penalty(late_submission_times.last.updated_at, submission_due_date)
    else
      handle_no_submission(submission_records)
    end
  end
  
  def get_submission_due_date
    AssignmentDueDate.where(deadline_type_id: @submission_deadline_type_id, parent_id: @assignment.id).first.due_at
  end
  
  def get_late_submission_times(submission_records, submission_due_date)
    submission_records.select { |submission_record| submission_record.updated_at > submission_due_date }
  end
  
  def calculate_late_submission_penalty(last_submission_time, submission_due_date)
    return 0 if last_submission_time <= submission_due_date
  
    time_difference = last_submission_time - submission_due_date
    penalty_units = calculate_penalty_units(time_difference, @penalty_unit)
    penalty_for_submission = penalty_units * @penalty_per_unit
    apply_max_penalty_limit(penalty_for_submission)
  end
  
  def handle_no_submission(submission_records)
    submission_records.any? ? 0 : @max_penalty_for_no_submission
  end
  
  def apply_max_penalty_limit(penalty_for_submission)
    if penalty_for_submission > @max_penalty_for_no_submission
      @max_penalty_for_no_submission
    else
      penalty_for_submission
    end
  end

  def calculate_review_penalty
    calculate_penalty(@assignment.num_reviews, @review_deadline_type_id, ReviewResponseMap, :get_reviewer)
  end
  
  def calculate_meta_review_penalty
    calculate_penalty(@assignment.num_review_of_reviews, @meta_review_deadline_type_id, MetareviewResponseMap, :id)
  end
  
  private
  
  def calculate_penalty(num_reviews_required, deadline_type_id, mapping_class, reviewer_method)
    return 0 if num_reviews_required <= 0 || @penalty_per_unit.nil?
  
    review_mappings = mapping_class.where(reviewer_id: @participant.send(reviewer_method).id)
    review_due_date = AssignmentDueDate.where(deadline_type_id: deadline_type_id, parent_id: @assignment.id).first
    return 0 if review_due_date.nil?
  
    compute_penalty_on_reviews(review_mappings, review_due_date.due_at, num_reviews_required)
  end

  def compute_penalty_on_reviews(review_mappings, review_due_date, num_of_reviews_required, penalty_unit, penalty_per_unit, max_penalty)
    review_timestamps = collect_review_timestamps(review_mappings)
    review_timestamps.sort!
    
    penalty = 0
  
    num_of_reviews_required.times do |i|
      if review_timestamps[i]
        penalty += calculate_review_penalty(review_timestamps[i], review_due_date, penalty_unit, penalty_per_unit, max_penalty)
      else
        penalty = apply_max_penalty_if_missing(max_penalty)
      end
    end
  
    penalty
  end
  
  private
  
  def collect_review_timestamps(review_mappings)
    review_mappings.filter_map do |map|
      Response.find_by(map_id: map.id)&.created_at unless map.response.empty?
    end
  end
  
  def calculate_review_penalty(submission_date, due_date, penalty_unit, penalty_per_unit, max_penalty)
    return 0 if submission_date <= due_date
  
    time_difference = submission_date - due_date
    penalty_units = calculate_penalty_units(time_difference, penalty_unit)
    [penalty_units * penalty_per_unit, max_penalty].min
  end
  
  def apply_max_penalty_if_missing(max_penalty)
    max_penalty
  end

  def calculate_penalty_units(time_difference, penalty_unit)
    case penalty_unit
    when 'Minute'
      time_difference / 60
    when 'Hour'
      time_difference / 3600
    when 'Day'
      time_difference / 86_400
    end
  end
end