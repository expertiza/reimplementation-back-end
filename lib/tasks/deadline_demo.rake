# frozen_string_literal: true

namespace :deadline do
  desc "Demonstrate the new DeadlineType and DueDate functionality"
  task demo: :environment do
    puts "=" * 80
    puts "DeadlineType and DueDate Refactoring Demo"
    puts "=" * 80
    puts

    # Step 1: Seed deadline types and rights
    puts "1. Setting up DeadlineTypes and DeadlineRights..."
    DeadlineType.seed_deadline_types!
    DeadlineRight.seed_deadline_rights!
    DeadlineType.cleanup_duplicates!

    puts "   Created #{DeadlineType.count} deadline types:"
    DeadlineType.all.order(:id).each do |dt|
      puts "   - #{dt.name} (ID: #{dt.id}): #{dt.description}"
    end
    puts

    puts "   Created #{DeadlineRight.count} deadline rights:"
    DeadlineRight.all.order(:id).each do |dr|
      puts "   - #{dr.name} (ID: #{dr.id}): #{dr.description}"
    end
    puts

    # Step 2: Create a demo assignment
    puts "2. Creating demo assignment..."
    assignment = Assignment.create!(
      name: "Demo Assignment - DueDate Refactor",
      description: "Demonstration of the new deadline system",
      max_team_size: 3,
      instructor: User.find_by(role: Role.find_by(name: 'Instructor')) || User.first
    )

    puts "   Created assignment: #{assignment.name} (ID: #{assignment.id})"
    puts

    # Step 3: Create due dates using the new API
    puts "3. Creating due dates using new DeadlineType integration..."

    submission_deadline = assignment.create_due_date(
      'submission',
      2.weeks.from_now,
      submission_allowed_id: DeadlineRight::OK,
      review_allowed_id: DeadlineRight::NO,
      teammate_review_allowed_id: DeadlineRight::NO,
      quiz_allowed_id: DeadlineRight::NO,
      round: 1
    )

    review_deadline = assignment.create_due_date(
      'review',
      3.weeks.from_now,
      submission_allowed_id: DeadlineRight::LATE,
      review_allowed_id: DeadlineRight::OK,
      teammate_review_allowed_id: DeadlineRight::NO,
      quiz_allowed_id: DeadlineRight::NO,
      round: 1
    )

    teammate_review_deadline = assignment.create_due_date(
      'teammate_review',
      4.weeks.from_now,
      submission_allowed_id: DeadlineRight::NO,
      review_allowed_id: DeadlineRight::LATE,
      teammate_review_allowed_id: DeadlineRight::OK,
      quiz_allowed_id: DeadlineRight::NO,
      round: 1
    )

    quiz_deadline = assignment.create_due_date(
      'quiz',
      1.week.from_now,
      submission_allowed_id: DeadlineRight::NO,
      review_allowed_id: DeadlineRight::NO,
      teammate_review_allowed_id: DeadlineRight::NO,
      quiz_allowed_id: DeadlineRight::OK,
      round: 1
    )

    puts "   Created #{assignment.due_dates.count} deadlines for the assignment"
    puts

    # Step 4: Demonstrate DeadlineType semantic methods
    puts "4. DeadlineType semantic methods demo:"
    puts "   submission.submission? = #{DeadlineType.submission.submission?}"
    puts "   submission.review? = #{DeadlineType.submission.review?}"
    puts "   review.review? = #{DeadlineType.review.review?}"
    puts "   teammate_review.review? = #{DeadlineType.teammate_review.review?}"
    puts "   quiz.allows_quiz? = #{DeadlineType.quiz.allows_quiz?}"
    puts "   DeadlineType.for_action('submit') = #{DeadlineType.for_action('submit')&.name}"
    puts "   DeadlineType.for_action('review') = #{DeadlineType.for_action('review')&.name}"
    puts

    # Step 5: Demonstrate DueDate instance methods
    puts "5. DueDate instance methods demo:"
    assignment.due_dates.each do |due_date|
      puts "   #{due_date.deadline_type_name.ljust(15)} | #{due_date.time_description} | Status: #{due_date.status_description}"
    end
    puts

    # Step 6: Demonstrate permission checking
    puts "6. Permission checking demo:"
    puts "   Assignment permissions summary:"
    permissions = assignment.action_permissions_summary
    permissions.each do |action, allowed|
      status = allowed ? "✓ ALLOWED" : "✗ DENIED"
      puts "     #{action.to_s.ljust(15)} : #{status}"
    end
    puts

    # Step 7: Demonstrate deadline queries
    puts "7. Deadline query methods demo:"
    puts "   Next due date: #{assignment.next_due_date&.summary&.dig(:deadline_type) || 'None'}"
    puts "   Upcoming deadlines: #{assignment.upcoming_deadlines.count}"
    puts "   Overdue deadlines: #{assignment.overdue_deadlines.count}"
    puts "   Has future deadlines: #{assignment.has_future_deadlines?}"
    puts "   Used deadline types: #{assignment.used_deadline_types.map(&:name).join(', ')}"
    puts

    # Step 8: Demonstrate workflow stage tracking
    puts "8. Workflow stage tracking demo:"
    puts "   Current workflow stage: #{assignment.current_workflow_stage}"
    puts "   Workflow stages: #{assignment.workflow_stages.join(' → ')}"
    puts "   Stage completion status:"
    assignment.stage_completion_status.each do |stage_info|
      status = stage_info[:completed] ? "✓ COMPLETED" : "○ PENDING"
      puts "     #{stage_info[:stage].ljust(15)} : #{status}"
    end
    puts

    # Step 9: Demonstrate deadline copying
    puts "9. Deadline copying demo:"
    copied_assignment = assignment.copy
    puts "   Original assignment deadlines: #{assignment.due_dates.count}"
    puts "   Copied assignment deadlines: #{copied_assignment.due_dates.count}"
    puts "   Copy successful: #{assignment.due_dates.count == copied_assignment.due_dates.count}"
    puts

    # Step 10: Demonstrate topic-specific deadlines
    puts "10. Topic-specific deadline demo..."

    # Create a sign up topic
    topic = SignUpTopic.create!(
      topic_name: "Demo Topic",
      topic_identifier: "DEMO-001",
      max_choosers: 5,
      assignment: assignment
    )

    # Create topic-specific deadline that differs from assignment
    topic_submission = topic.create_due_date(
      'submission',
      10.days.from_now,  # Different from assignment deadline
      submission_allowed_id: DeadlineRight::OK,
      review_allowed_id: DeadlineRight::NO,
      teammate_review_allowed_id: DeadlineRight::NO,
      quiz_allowed_id: DeadlineRight::NO,
      round: 1
    )

    puts "   Created topic: #{topic.topic_name}"
    puts "   Topic submission deadline: #{topic_submission.due_at.strftime('%B %d, %Y')}"
    puts "   Assignment submission deadline: #{submission_deadline.due_at.strftime('%B %d, %Y')}"
    puts "   Topic has deadline overrides: #{assignment.has_topic_deadline_overrides?}"

    # Demonstrate topic deadline resolution
    effective_deadline = assignment.effective_deadline_for_topic(topic.id, 'submission')
    puts "   Effective deadline for topic: #{effective_deadline.due_at.strftime('%B %d, %Y')} (#{effective_deadline.parent_type})"
    puts

    # Step 11: Demonstrate deadline conflicts detection
    puts "11. Deadline conflict detection demo:"
    conflicts = assignment.deadline_conflicts_for_topic(topic.id)
    if conflicts.any?
      puts "   Found #{conflicts.count} deadline conflicts:"
      conflicts.each do |conflict|
        puts "     #{conflict[:deadline_type]}: Assignment (#{conflict[:assignment_due].strftime('%m/%d')}) vs Topic (#{conflict[:topic_due].strftime('%m/%d')})"
      end
    else
      puts "   No deadline conflicts detected"
    end
    puts

    # Step 12: Demonstrate deadline validation
    puts "12. Deadline validation demo:"
    puts "   Deadlines properly ordered: #{assignment.deadlines_properly_ordered?}"
    violations = assignment.deadline_ordering_violations
    if violations.any?
      puts "   Ordering violations found:"
      violations.each do |violation|
        puts "     #{violation[:issue]}"
      end
    else
      puts "   No ordering violations found"
    end
    puts

    # Step 13: Demonstrate permission status details
    puts "13. Permission status details demo:"
    assignment.due_dates.includes(:deadline_type).each do |due_date|
      puts "   #{due_date.deadline_type_name.ljust(15)}:"
      puts "     Submission: #{due_date.permission_description_for(:submission)}"
      puts "     Review:     #{due_date.permission_description_for(:review)}"
      puts "     Quiz:       #{due_date.permission_description_for(:quiz)}"
    end
    puts

    # Step 14: Demonstrate collection statistics
    puts "14. Collection statistics demo:"
    stats = DueDate.collection_stats(assignment.due_dates)
    puts "   Total deadlines: #{stats[:total]}"
    puts "   Upcoming: #{stats[:upcoming]}"
    puts "   Overdue: #{stats[:overdue]}"
    puts "   Due today: #{stats[:due_today]}"
    puts "   Currently active: #{stats[:active]}"
    puts "   Deadline types: #{stats[:types].join(', ')}"
    puts

    # Step 15: Clean up
    puts "15. Cleaning up demo data..."
    copied_assignment.destroy
    assignment.destroy
    puts "   Demo completed successfully!"
    puts
    puts "=" * 80
    puts "Summary of New Features Demonstrated:"
    puts "- ✓ DeadlineType model as canonical source of truth"
    puts "- ✓ Semantic helper methods for deadline types"
    puts "- ✓ DueDate refactored with instance methods"
    puts "- ✓ Permission checking through mixins"
    puts "- ✓ Unified deadline querying"
    puts "- ✓ Topic-specific deadline overrides"
    puts "- ✓ Workflow stage tracking"
    puts "- ✓ Deadline copying and duplication"
    puts "- ✓ Conflict detection and validation"
    puts "- ✓ Comprehensive permission status"
    puts "=" * 80
  end

  desc "Clean up any duplicate deadline types"
  task cleanup_duplicates: :environment do
    puts "Cleaning up duplicate deadline types..."
    DeadlineType.cleanup_duplicates!
    puts "Cleanup completed."
  end

  desc "Seed deadline types and rights"
  task seed: :environment do
    puts "Seeding deadline types..."
    DeadlineType.seed_deadline_types!
    puts "Seeding deadline rights..."
    DeadlineRight.seed_deadline_rights!
    puts "Seeding completed."
  end

  desc "Show deadline statistics"
  task stats: :environment do
    puts "Deadline System Statistics"
    puts "=" * 50
    puts "DeadlineTypes: #{DeadlineType.count}"
    DeadlineType.all.each do |dt|
      puts "  #{dt.name}: #{dt.due_dates_count} due dates"
    end
    puts
    puts "DeadlineRights: #{DeadlineRight.count}"
    DeadlineRight.all.each do |dr|
      puts "  #{dr.name}: #{dr.usage_count} usages"
    end
    puts
    puts "DueDates: #{DueDate.count}"
    puts "  Upcoming: #{DueDate.upcoming.count}"
    puts "  Overdue: #{DueDate.overdue.count}"
    puts "  Due today: #{DueDate.today.count}"
    puts
  end
end
