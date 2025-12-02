# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assignment, type: :model do
  let(:team) { Team.new }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', item_id: 1) }
  let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', item_id: 1) }

  describe '.get_all_review_comments' do
    it 'returns concatenated review comments and # of reviews in each round' do
      allow(Assignment).to receive(:find).with(1).and_return(assignment)
      allow(assignment).to receive(:num_review_rounds).and_return(2)
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:responses).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer])
      allow(response2).to receive(:scores).and_return([answer2])
      expect(assignment.get_all_review_comments(1)).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  # Get a collection of all comments across all rounds of a review as well as a count of the total number of comments. Returns the above
  # information both for totals and in a list per-round.
  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(assignment).to receive(:get_all_review_comments).with(1)
                                                            .and_return([
                                                                          [nil, 'Answer text', 'Answer textLGTM',
                                                                           ''], [nil, 1, 1, 0]
                                                                        ])
      expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
    end
  end

  # Create deadline types for testing
  let!(:submission_type) { DeadlineType.create(name: 'submission', description: 'Submission deadline') }
  let!(:review_type) { DeadlineType.create(name: 'review', description: 'Review deadline') }
  let!(:quiz_type) { DeadlineType.create(name: 'quiz', description: 'Quiz deadline') }

  # Create deadline rights for testing
  let!(:ok_right) { DeadlineRight.create(name: 'OK', description: '') }
  let!(:late_right) { DeadlineRight.create(name: 'Late', description: '') }
  let!(:no_right) { DeadlineRight.create(name: 'No', description: '') }

  describe '#activity_permissible?' do
    context 'when next_due_date allows the activity' do
      let!(:due_date) do
        DueDate.create!(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: late_right.id
        )
      end

      it 'returns true for allowed activity' do
        expect(assignment.activity_permissible?(:submission)).to eq(true)
      end
    end

    context 'when no upcoming due_date exists' do
      it 'returns false' do
        expect(assignment.activity_permissible?(:submission)).to eq(false)
      end
    end
  end

  describe '#submission_permissible?' do
    it 'delegates to activity_permissible?' do
      allow(assignment).to receive(:activity_permissible?).with(:submission).and_return(true)
      expect(assignment.submission_permissible?).to eq(true)
    end
  end

  describe '#activity_permissible_for?' do
    include ActiveSupport::Testing::TimeHelpers

    let!(:past_due_date) do
      DueDate.create!(
        parent: assignment,
        due_at: 2.days.ago,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,    # submission = true
        review_allowed_id: no_right.id
      )
    end

    let!(:future_due_date) do
      DueDate.create!(
        parent: assignment,
        due_at: 3.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: no_right.id,    # submission = false
        review_allowed_id: ok_right.id
      )
    end

    it 'returns permission of the most recent past deadline' do
      result = assignment.activity_permissible_for?(:submission, Time.current)
      expect(result).to eq(true) # OK from past_due_date
    end

    it 'returns false when the most recent past deadline forbids the activity' do
      # past due date forbids submission now
      past_due_date.update!(submission_allowed_id: no_right.id)

      result = assignment.activity_permissible_for?(:submission, Time.current)
      expect(result).to eq(false)
    end

    it 'ignores future deadlines when evaluating permissions' do
      # Even though future due date forbids submission,
      # the past due date is still used because deadline_date = Time.now
      expect(assignment.activity_permissible_for?(:submission, Time.current)).to eq(true)
    end

    it 'uses a future-point-in-time to select future deadline' do
      travel_to(4.days.from_now) do
        result = assignment.activity_permissible_for?(:submission, Time.current)
        expect(result).to eq(false) # now future_due_date becomes the "past" one
      end
    end

    it 'returns false when no deadlines exist before the given time' do
      travel_to(3.days.ago - 1.hour) do
        result = assignment.activity_permissible_for?(:submission, Time.current)
        expect(result).to eq(false)
      end
    end
  end

  describe '#next_due_date' do
    it 'returns the earliest upcoming due date' do
      due1 = DueDate.create!(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: no_right.id
      )
      due2 = DueDate.create!(
        parent: assignment,
        due_at: 5.days.from_now,
        deadline_type: review_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: no_right.id
      )

      expect(assignment.next_due_date).to eq(due1)
    end

    it 'returns nil when no upcoming due dates' do
      expect(assignment.next_due_date).to eq(nil)
    end
  end

  describe '#deadlines_properly_ordered?' do
    it 'returns true when chronological' do
      DueDate.create!(
        parent: assignment,
        due_at: 1.day.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: no_right.id
      )
      DueDate.create!(
        parent: assignment,
        due_at: 3.days.from_now,
        deadline_type: review_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: no_right.id
      )

      expect(assignment.deadlines_properly_ordered?).to eq(true)
    end

    it 'returns false when ordering wrong' do
      DueDate.create!(
        parent: assignment,
        due_at: 3.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
      DueDate.create!(
        parent: assignment,
        due_at: 1.day.from_now,
        deadline_type: review_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )

      expect(assignment.deadlines_properly_ordered?).to eq(false)
    end
  end
end
