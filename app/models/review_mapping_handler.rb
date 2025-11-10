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
  def assign_calibration_review(reviewer, calibration_submission)
    ReviewResponseMap.create!(
      reviewer: reviewer,
      reviewee: calibration_submission.team,
      reviewed_object_id: calibration_submission.assignment_id,
      calibration: true
    )
  end

  def calibration_reviews_for(reviewer)
    ReviewResponseMap.where(reviewer: reviewer, calibration: true)
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

  def create_mapping(reviewer, team)
    ReviewResponseMap.create!(
      reviewer: reviewer,
      reviewee: team,
      reviewed_object_id: @assignment.id
    )
  end
end
