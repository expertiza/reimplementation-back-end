# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DueDate, type: :model do
  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil) }
  let(:instructor) do
    Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456',
                      role: role)
  end
  let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor: instructor) }
  let(:assignment2) { Assignment.create(id: 2, name: 'Test Assignment2', instructor: instructor) }

  # Create deadline types for testing
  let!(:submission_type) { DeadlineType.create(name: 'submission', description: 'Submission deadline') }
  let!(:review_type) { DeadlineType.create(name: 'review', description: 'Review deadline') }
  let!(:quiz_type) { DeadlineType.create(name: 'quiz', description: 'Quiz deadline') }

  # Create deadline rights for testing
  let!(:ok_right) { DeadlineRight.create(name: 'OK', description: '') }
  let!(:late_right) { DeadlineRight.create(name: 'Late', description: '') }
  let!(:no_right) { DeadlineRight.create(name: 'No', description: '') }

  describe 'validations' do
    it 'is invalid without a parent' do
      due_date = DueDate.new(
        parent: nil,
        due_at: 2.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
      expect(due_date).to be_invalid
      expect(due_date.errors[:parent]).to include('must exist')
    end

    it 'is invalid without a due_at' do
      due_date = DueDate.new(
        parent: assignment,
        due_at: nil,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
      expect(due_date).to be_invalid
      expect(due_date.errors[:due_at]).to include("can't be blank")
    end

    it 'is invalid without a deadline_type_id' do
      due_date = DueDate.new(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type_id: nil,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
      expect(due_date).to be_invalid
      expect(due_date.errors[:deadline_type_id]).to include("can't be blank")
    end

    it 'is valid with required fields' do
      due_date = DueDate.create(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
      expect(due_date).to be_valid
    end

    it 'validates round is greater than 0 when present' do
      due_date = DueDate.new(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id,
        round: 0
      )
      expect(due_date).to be_invalid
      expect(due_date.errors[:round]).to be_present
    end

    it 'allows nil round' do
      due_date = DueDate.create(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id,
        round: nil
      )
      expect(due_date).to be_valid
    end
  end

  describe 'scopes' do
    let!(:past_due_date) do
      DueDate.create(
        parent: assignment,
        due_at: 2.days.ago,
        deadline_type: submission_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
    end

    let!(:upcoming_due_date1) do
      DueDate.create(
        parent: assignment,
        due_at: 2.days.from_now,
        deadline_type: review_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
    end

    let!(:upcoming_due_date2) do
      DueDate.create(
        parent: assignment,
        due_at: 5.days.from_now,
        deadline_type: quiz_type,
        submission_allowed_id: ok_right.id,
        review_allowed_id: ok_right.id
      )
    end

    describe '.upcoming' do
      it 'returns only future due dates ordered by due_at' do
        upcoming = DueDate.upcoming
        expect(upcoming).to eq([upcoming_due_date1, upcoming_due_date2])
      end
    end

    describe '.overdue' do
      it 'returns only past due dates ordered by due_at' do
        overdue = DueDate.overdue
        expect(overdue).to eq([past_due_date])
      end
    end

    describe '.for_round' do
      let!(:round1_due_date) do
        DueDate.create(
          parent: assignment,
          due_at: 3.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id,
          round: 1
        )
      end

      let!(:round2_due_date) do
        DueDate.create(
          parent: assignment,
          due_at: 4.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id,
          round: 2
        )
      end

      it 'returns due dates for a specific round' do
        expect(DueDate.for_round(1)).to include(round1_due_date)
        expect(DueDate.for_round(1)).not_to include(round2_due_date)
      end
    end

    describe '.for_deadline_type' do
      it 'returns due dates for a specific deadline type' do
        submission_dates = DueDate.for_deadline_type('submission')
        expect(submission_dates).to include(past_due_date)
        expect(submission_dates).not_to include(upcoming_due_date1)
      end
    end
  end

  describe 'instance methods' do
    describe '#overdue?' do
      it 'returns true for past due dates' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 1.day.ago,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        expect(due_date.overdue?).to be true
      end

      it 'returns false for future due dates' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 1.day.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        expect(due_date.overdue?).to be false
      end
    end

    describe '#upcoming?' do
      it 'returns true for future due dates' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 1.day.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        expect(due_date.upcoming?).to be true
      end

      it 'returns false for past due dates' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 1.day.ago,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        expect(due_date.upcoming?).to be false
      end
    end

    describe '#set' do
      it 'updates deadline_type_id, parent_id, and round' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        expect(due_date.deadline_type_id).to eq(submission_type.id)
        expect(due_date.parent_id).to eq(assignment.id)
        expect(due_date.round).to eq(1) # default value

        due_date.set(review_type.id, assignment2.id, 2)
        due_date.reload

        expect(due_date.deadline_type_id).to eq(review_type.id)
        expect(due_date.parent_id).to eq(assignment2.id)
        expect(due_date.round).to eq(2)
      end
    end

    describe '#copy' do
      it 'creates a duplicate due date for a new assignment' do
        original = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: late_right.id,
          round: 1
        )

        copied = original.copy(assignment2.id)

        expect(copied).to be_persisted
        expect(copied.id).not_to eq(original.id)
        expect(copied.parent_id).to eq(assignment2.id)
        expect(copied.due_at).to eq(original.due_at)
        expect(copied.deadline_type_id).to eq(original.deadline_type_id)
        expect(copied.submission_allowed_id).to eq(original.submission_allowed_id)
        expect(copied.review_allowed_id).to eq(original.review_allowed_id)
        expect(copied.round).to eq(original.round)
      end
    end

    describe '#deadline_type_name' do
      it 'returns the name of the associated deadline type' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        expect(due_date.deadline_type_name).to eq('submission')
      end
    end

    describe '#last_deadline?' do
      it 'returns true if this is the last deadline for the parent' do
        last_deadline = DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        expect(last_deadline.last_deadline?).to be true
      end

      it 'returns false if there are later deadlines' do
        earlier_deadline = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        expect(earlier_deadline.last_deadline?).to be false
      end
    end

    describe '#<=>' do
      it 'compares due dates by their due_at time' do
        earlier = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        later = DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        expect(earlier <=> later).to eq(-1)
        expect(later <=> earlier).to eq(1)
        expect(earlier <=> earlier).to eq(0)
      end
    end
  end

  describe 'class methods' do
    describe '.sort_due_dates' do
      it 'sorts due dates from earliest to latest' do
        due_date1 = DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        due_date2 = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        due_date3 = DueDate.create(
          parent: assignment,
          due_at: 1.day.ago,
          deadline_type: quiz_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        sorted = DueDate.sort_due_dates([due_date1, due_date2, due_date3])
        expect(sorted).to eq([due_date3, due_date2, due_date1])
      end
    end

    describe '.any_future_due_dates?' do
      it 'returns true when future due dates exist' do
        due_dates = [
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          ),
          DueDate.create(
            parent: assignment,
            due_at: 5.days.from_now,
            deadline_type: review_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        ]

        expect(DueDate.any_future_due_dates?(due_dates)).to be true
      end

      it 'returns false when no future due dates exist' do
        due_dates = [
          DueDate.create(
            parent: assignment,
            due_at: 2.days.ago,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          ),
          DueDate.create(
            parent: assignment,
            due_at: 5.days.ago,
            deadline_type: review_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        ]

        expect(DueDate.any_future_due_dates?(due_dates)).to be false
      end
    end

    describe '.copy' do
      it 'copies all due dates from one assignment to another' do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id,
          round: 1
        )

        DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: review_type,
          review_allowed_id: late_right.id,
          submission_allowed_id: ok_right.id,
          round: 1
        )

        original_count = assignment.due_dates.count
        expect(assignment2.due_dates.count).to eq(0)

        DueDate.copy(assignment.id, assignment2.id)

        expect(assignment2.due_dates.count).to eq(original_count)

        assignment.due_dates.each_with_index do |original, index|
          copied = assignment2.due_dates[index]
          expect(copied.due_at).to eq(original.due_at)
          expect(copied.deadline_type_id).to eq(original.deadline_type_id)
          expect(copied.round).to eq(original.round)
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :set_default_round' do
      it 'sets round to 1 when not specified' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )

        expect(due_date.round).to eq(1)
      end

      it 'does not override explicitly set round' do
        due_date = DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id,
          round: 3
        )

        expect(due_date.round).to eq(3)
      end
    end
  end
end
