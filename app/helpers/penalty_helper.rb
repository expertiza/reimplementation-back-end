# frozen_string_literal: true

module PenaltyHelper
  # Returns the grade after deducting the submission late penalty.
  # Returns nil when there is no raw grade. Extracted here because the same
  # deduction is needed anywhere a raw grade is shown alongside a deadline policy.
  def penalized_submission_grade(raw_grade, participant_id)
    return nil if raw_grade.nil?

    penalty = penalty_for(participant_id)[:submission]
    (raw_grade - penalty).round(2)
  end

  # Returns late penalties for each submission type for the given participant.
  # Returns zeroes for all types when the assignment has no late policy.
  def penalty_for(participant_id)
    participant = AssignmentParticipant.find(participant_id)
    assignment  = participant.assignment

    return zero_penalties unless assignment.late_policy_id

    policy = LatePolicy.find(assignment.late_policy_id)
    return zero_penalties unless policy.penalty_per_unit

    {
      submission: submission_penalty(participant, assignment, policy),
      review:     review_penalty(participant, assignment, policy)
    }
  end

  private

  def zero_penalties
    { submission: 0, review: 0 }
  end

  def submission_penalty(participant, assignment, policy)
    due_date_record = AssignmentDueDate.where(
      deadline_type_id: ExpertizaConstants::DeadlineTypes::SUBMISSION,
      parent_id: assignment.id
    ).first
    return 0 unless due_date_record

    due_date     = due_date_record.due_at
    records      = SubmissionRecord.where(team_id: participant.team.id, assignment_id: assignment.id)
    late_records = records.select { |r| r.updated_at > due_date }

    if late_records.any?
      late_penalty(late_records.last.updated_at, due_date, policy)
    elsif records.any?
      0
    else
      policy.max_penalty
    end
  end

  def review_penalty(participant, assignment, policy)
    return 0 if assignment.num_reviews.to_i <= 0

    due_date_record = AssignmentDueDate.where(
      deadline_type_id: ExpertizaConstants::DeadlineTypes::REVIEW,
      parent_id: assignment.id
    ).first
    return 0 unless due_date_record

    reviewer_id = participant.get_reviewer.id
    mappings    = ReviewResponseMap.where(reviewer_id: reviewer_id)
    accumulated_review_penalty(mappings, due_date_record.due_at, assignment.num_reviews, policy)
  end

  # Accumulates the late penalty across all required reviews for a reviewer.
  # If a review is missing entirely, the full max_penalty is charged for that slot.
  def accumulated_review_penalty(mappings, due_date, num_required, policy)
    timestamps = review_submission_timestamps(mappings)

    total = 0
    num_required.times do |i|
      total += if timestamps[i]
                 late_penalty(timestamps[i], due_date, policy)
               else
                 policy.max_penalty
               end
    end
    total
  end

  # Returns the created_at timestamp of the first response for each map that has one.
  # Maps with no response are omitted; the result may be shorter than mappings.
  def review_submission_timestamps(mappings)
    mappings.filter_map do |map|
      Response.find_by(map_id: map.id)&.created_at unless map.response.empty?
    end
  end

  # Returns the penalty for a single late submission; 0 if on time.
  # Capped at policy.max_penalty.
  def late_penalty(submitted_at, due_at, policy)
    return 0 if submitted_at <= due_at

    units = penalty_units(submitted_at - due_at, policy.penalty_unit)
    [units * policy.penalty_per_unit, policy.max_penalty].min
  end

  # Converts a time difference (in seconds) to the number of penalty units
  # based on the policy's unit (Minute, Hour, or Day).
  def penalty_units(time_difference, unit)
    case unit
    when 'Minute' then time_difference / 60
    when 'Hour'   then time_difference / 3600
    when 'Day'    then time_difference / 86_400
    else 0
    end
  end
end
