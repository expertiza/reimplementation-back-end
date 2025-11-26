# frozen_string_literal: true

namespace :deadline do
  desc "Demonstrate the simplified due date functionality"
  task demo: :environment do
    puts "=" * 80
    puts "Simplified Due Date System Demo"
    puts "=" * 80
    puts

    puts "1. Creating demo assignment..."
    assignment = Assignment.create!(
      name: "Demo Assignment - Simplified DueDate",
      description: "Demonstration of the simplified deadline system",
      max_team_size: 3,
      instructor: User.find_by(role: Role.find_by(name: 'Instructor')) || User.first
    )

    puts "Created assignment: #{assignment.name} (ID: #{assignment.id})"
    puts

    puts "2. Creating due dates..."

    submission_deadline = DueDate.create!(
      parent: assignment,
      deadline_type_id: 1,
      due_at: 2.weeks.from_now,
      submission_allowed_id: 3,
      review_allowed_id: 1,
      teammate_review_allowed_id: 1,
      quiz_allowed_id: 1,
      round: 1
    )

    review_deadline = DueDate.create!(
      parent: assignment,
      deadline_type_id: 2,
      due_at: 3.weeks.from_now,
      submission_allowed_id: 2,
      review_allowed_id: 3,
      teammate_review_allowed_id: 1,
      quiz_allowed_id: 1,
      round: 1
    )

    teammate_review_deadline = DueDate.create!(
      parent: assignment,
      deadline_type_id: 3,
      due_at: 4.weeks.from_now,
      submission_allowed_id: 1,
      review_allowed_id: 2,
      teammate_review_allowed_id: 3,
      quiz_allowed_id: 1,
      round: 1
    )

    puts "Created #{assignment.due_dates.count} deadlines for the assignment"
    puts

    puts "3. Permission checking demo:"
    puts "Can submit: #{assignment.submission_permissible?}"
    puts "Can review: #{assignment.review_permissible?}"
    puts "Can teammate review: #{assignment.teammate_review_permissible?}"
    puts "Can take quiz: #{assignment.quiz_permissible?}"
    puts

    puts "4. Deadline query methods demo:"
    next_deadline = assignment.next_due_date
    puts "Next due date: #{next_deadline&.deadline_type_name || 'None'}"
    puts "Current stage: #{assignment.current_stage}"
    puts "Has topic specific deadlines: #{assignment.has_topic_specific_deadlines?}"
    puts

    puts "5. Due date properties demo:"
    assignment.due_dates.each do |due_date|
      puts "#{due_date.deadline_type_name.ljust(15)} | #{due_date.overdue? ? 'Overdue' : 'Upcoming'} | #{due_date.to_s}"
    end
    puts

    puts "6. Deadline copying demo..."
    new_assignment = Assignment.create!(
      name: "Copied Assignment",
      description: "Copy of demo assignment",
      max_team_size: 3,
      instructor: assignment.instructor
    )

    assignment.copy_due_dates_to(new_assignment)
    puts "Original assignment deadlines: #{assignment.due_dates.count}"
    puts "Copied assignment deadlines: #{new_assignment.due_dates.count}"
    puts "Copy successful: #{assignment.due_dates.count == new_assignment.due_dates.count}"
    puts

    puts "7. Topic-specific deadline demo..."

    topic = SignUpTopic.create!(
      topic_name: "Demo Topic",
      topic_identifier: "DEMO-001",
      max_choosers: 5,
      assignment: assignment
    )

    topic_submission = DueDate.create!(
      parent: topic,
      deadline_type_id: 1,
      due_at: 10.days.from_now,
      submission_allowed_id: 3,
      review_allowed_id: 1,
      teammate_review_allowed_id: 1,
      quiz_allowed_id: 1,
      round: 1
    )

    puts "Created topic: #{topic.topic_name}"
    puts "Topic submission deadline: #{topic_submission.due_at.strftime('%B %d, %Y')}"
    puts "Assignment submission deadline: #{submission_deadline.due_at.strftime('%B %d, %Y')}"
    puts

    puts "8. Deadline ordering demo:"
    puts "Deadlines properly ordered: #{assignment.deadlines_properly_ordered?}"
    puts

    puts "9. Class method demos:"
    all_due_dates = assignment.due_dates.to_a
    sorted_dates = DueDate.sort_due_dates(all_due_dates)
    puts "Sorted #{sorted_dates.count} due dates chronologically"
    puts "Any future due dates: #{DueDate.any_future_due_dates?(all_due_dates)}"
    puts

    puts "10. Cleaning up demo data..."
    new_assignment.destroy
    assignment.destroy
    puts "Demo completed successfully!"
    puts
    puts "=" * 80
    puts "Summary of Features Demonstrated:"
    puts "- Basic permission checking methods"
    puts "- Next due date functionality"
    puts "- Due date copying between assignments"
    puts "- Topic-specific deadline support"
    puts "- Chronological ordering validation"
    puts "- Class methods for date management"
    puts "=" * 80
  end

  desc "Show deadline statistics"
  task stats: :environment do
    puts "Deadline System Statistics"
    puts "=" * 50
    puts "DeadlineTypes: #{DeadlineType.count}"
    DeadlineType.all.each do |dt|
      puts "  #{dt.name}: #{dt.due_dates.count} due dates"
    end
    puts
    puts "DeadlineRights: #{DeadlineRight.count}"
    DeadlineRight.all.each do |dr|
      puts "  #{dr.name}: used in system"
    end
    puts
    puts "DueDates: #{DueDate.count}"
    puts "  Upcoming: #{DueDate.upcoming.count}"
    puts "  Overdue: #{DueDate.overdue.count}"
    puts
  end

  desc "Test basic due date functionality"
  task test: :environment do
    puts "Testing basic due date functionality..."

    submission_type = DeadlineType.find_by_name('submission')
    puts "Submission type found: #{submission_type.present?}"

    ok_right = DeadlineRight.find_by_name('OK')
    puts "OK right found: #{ok_right.present?}"

    puts "Basic functionality test completed."
  end
end
