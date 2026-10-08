class ReviewMappingHandler
  DEFAULT_OUTSTANDING_LIMIT = 2

  def initialize(assignment)
    @assignment = assignment
  end

  # ===== STATIC ASSIGNMENT =====
  # assign reviews statically using the given strategy e.g. Round Robin Strategy, CSV Import Strategy
  def assign_statically(strategy_class)
    strategy = strategy_class.new(@assignment)
    strategy.each_review_pair do |reviewer, team|
      create_mapping(reviewer, team)
    end
  end

  def assign_from_csv(csv_text)
    strategy = ReviewMappingStrategies::CsvImportStrategy.new(@assignment, csv_text)
    strategy.each_review_pair do |reviewer, team|
      create_mapping(reviewer, team)
    end
  end


  def assign_random
    strategy = ReviewMappingStrategies::RandomStaticStrategy.new(@assignment)
    strategy.each_review_pair do |reviewer, team|
      create_mapping(reviewer, team)
    end
  end


  # ===== DYNAMIC ASSIGNMENT =====
  def assign_dynamically(strategy_class, reviewer, k: DEFAULT_OUTSTANDING_LIMIT)
    return nil unless can_accept_more_reviews?(reviewer, k: k)

    strategy = strategy_class.new(@assignment)
    team = strategy.assign_one(reviewer)
    return nil unless team

    create_mapping(reviewer, team)
  end

  def assign_dynamic_topic_fairly(reviewer, k: 1)
    return nil unless can_accept_more_reviews?(reviewer, k: DEFAULT_OUTSTANDING_LIMIT)

    strategy = ReviewMappingStrategies::LeastReviewedTopicStrategy.new(@assignment)
    team = strategy.assign_one(reviewer, k: k)
    return nil unless team

    create_mapping(reviewer, team)
  end

  # ===== CALIBRATION =====
  # Assigns calibration reviews to all student participants in round-robin order.
  # Calibration reviews are a special case of round-robin assignment: teams are
  # filtered to those the instructor has already reviewed with for_calibration: true,
  # and each created mapping also carries for_calibration: true.
  def assign_calibration_reviews_round_robin
    instructor_participant = AssignmentParticipant.find_by(
      parent_id: @assignment.id,
      user_id:   @assignment.instructor_id
    )
    return unless instructor_participant

    calibration_team_ids = ReviewResponseMap.where(
      reviewed_object_id: @assignment.id,
      reviewer_id:        instructor_participant.id,
      for_calibration:    true
    ).pluck(:reviewee_id)
    return if calibration_team_ids.empty?

    teams     = AssignmentTeam.where(id: calibration_team_ids)
    reviewers = AssignmentParticipant.where(parent_id: @assignment.id)
                                     .where.not(user_id: @assignment.instructor_id)

    assign_round_robin(reviewers, teams, reviews_per_reviewer: 2, for_calibration: true)
  end

  def calibration_reviews_for(reviewer)
    ReviewResponseMap.where(reviewer_id: reviewer.id, for_calibration: true)
  end

  # ===== OUTSTANDING REVIEWS =====
  def can_accept_more_reviews?(reviewer, k: DEFAULT_OUTSTANDING_LIMIT)
    outstanding = ReviewResponseMap.where(
      reviewer: reviewer,
      reviewed_object_id: @assignment.id,
      submitted: false
    ).count
    outstanding < k
  end

  # ===== DELETE =====
  def delete_review_mapping(mapping_id)
    ReviewResponseMap.find(mapping_id).destroy
  end

  def delete_all_reviews_for(reviewer)
    ReviewResponseMap.where(reviewer: reviewer).destroy_all
  end

  # ===== INSTRUCTOR GRADING =====
  def grade_review(mapping, grade:, comment:)
    mapping.update!(instructor_grade: grade, instructor_comment: comment)
  end

  private

  def assign_round_robin(reviewers, teams, reviews_per_reviewer: 1, for_calibration: false)
    reviewers.each_with_index do |reviewer, index|
      reviews_per_reviewer.times do |i|
        team = teams[(index + i) % teams.size]
        ReviewResponseMap.find_or_create_by!(
          reviewer_id:        reviewer.id,
          reviewee_id:        team.id,
          reviewed_object_id: @assignment.id,
          for_calibration:    for_calibration
        )
      end
    end
  end

  def create_mapping(reviewer, team)
    ReviewResponseMap.create!(
      reviewer: reviewer,
      reviewee: team,
      reviewed_object_id: @assignment.id
    )
  end
end
