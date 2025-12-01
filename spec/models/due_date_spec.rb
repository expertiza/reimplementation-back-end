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
    context 'when parent is missing' do
      let(:due_date) do
        DueDate.new(
          parent: nil,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'is invalid' do
        expect(due_date).to be_invalid
      end

      it 'has error on parent field' do
        due_date.valid?
        expect(due_date.errors[:parent]).to include('must exist')
      end
    end

    context 'when due_at is missing' do
      let(:due_date) do
        DueDate.new(
          parent: assignment,
          due_at: nil,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'is invalid' do
        expect(due_date).to be_invalid
      end

      it 'has error on due_at field' do
        due_date.valid?
        expect(due_date.errors[:due_at]).to include("can't be blank")
      end
    end

    context 'when deadline_type_id is missing' do
      let(:due_date) do
        DueDate.new(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type_id: nil,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'is invalid' do
        expect(due_date).to be_invalid
      end

      it 'has error on deadline_type_id field' do
        due_date.valid?
        expect(due_date.errors[:deadline_type_id]).to include("can't be blank")
      end
    end

    context 'when all required fields are present' do
      let(:due_date) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'is valid' do
        expect(due_date).to be_valid
      end

      it 'persists to database' do
        expect(due_date).to be_persisted
      end
    end

    context 'when round validation' do
      context 'with round value of 0' do
        let(:due_date) do
          DueDate.new(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: 0
          )
        end

        it 'is invalid' do
          expect(due_date).to be_invalid
        end

        it 'has error on round field' do
          due_date.valid?
          expect(due_date.errors[:round]).to be_present
        end
      end

      context 'with negative round value' do
        let(:due_date) do
          DueDate.new(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: -1
          )
        end

        it 'is invalid' do
          expect(due_date).to be_invalid
        end
      end

      context 'with nil round' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: nil
          )
        end

        it 'is valid' do
          expect(due_date).to be_valid
        end

        it 'sets default round to 1' do
          expect(due_date.round).to eq(1)
        end
      end

      context 'with positive round value' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: 3
          )
        end

        it 'is valid' do
          expect(due_date).to be_valid
        end

        it 'preserves the round value' do
          expect(due_date.round).to eq(3)
        end
      end
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
      it 'returns only future due dates' do
        upcoming = DueDate.upcoming
        expect(upcoming).to contain_exactly(upcoming_due_date1, upcoming_due_date2)
      end

      it 'orders results by due_at ascending' do
        upcoming = DueDate.upcoming
        expect(upcoming).to eq([upcoming_due_date1, upcoming_due_date2])
      end

      it 'excludes past due dates' do
        upcoming = DueDate.upcoming
        expect(upcoming).not_to include(past_due_date)
      end

      context 'when all due dates are in the past' do
        before do
          DueDate.destroy_all
          DueDate.create(
            parent: assignment,
            due_at: 3.days.ago,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns empty collection' do
          expect(DueDate.upcoming).to be_empty
        end
      end
    end

    describe '.overdue' do
      it 'returns only past due dates' do
        overdue = DueDate.overdue
        expect(overdue).to contain_exactly(past_due_date)
      end

      it 'orders results by due_at ascending' do
        past_due_date2 = DueDate.create(
          parent: assignment,
          due_at: 5.days.ago,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
        overdue = DueDate.overdue
        expect(overdue.first).to eq(past_due_date2)
      end

      it 'excludes future due dates' do
        overdue = DueDate.overdue
        expect(overdue).not_to include(upcoming_due_date1)
      end

      context 'when all due dates are in the future' do
        before do
          DueDate.destroy_all
          DueDate.create(
            parent: assignment,
            due_at: 3.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns empty collection' do
          expect(DueDate.overdue).to be_empty
        end
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

      it 'returns due dates for specified round' do
        expect(DueDate.for_round(1)).to include(round1_due_date)
      end

      it 'excludes due dates from other rounds' do
        expect(DueDate.for_round(1)).not_to include(round2_due_date)
      end

      context 'when round has no due dates' do
        it 'returns empty collection' do
          expect(DueDate.for_round(999)).to be_empty
        end
      end
    end

    describe '.for_deadline_type' do
      it 'returns due dates for specified deadline type' do
        submission_dates = DueDate.for_deadline_type('submission')
        expect(submission_dates).to include(past_due_date)
      end

      it 'excludes due dates with different deadline types' do
        submission_dates = DueDate.for_deadline_type('submission')
        expect(submission_dates).not_to include(upcoming_due_date1)
      end

      context 'when deadline type has no due dates' do
        it 'returns empty collection' do
          expect(DueDate.for_deadline_type('nonexistent')).to be_empty
        end
      end
    end
  end

  describe 'instance methods' do
    describe '#overdue?' do
      context 'when due date is in the past' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 1.day.ago,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns true' do
          expect(due_date.overdue?).to be true
        end
      end

      context 'when due date is in the future' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 1.day.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns false' do
          expect(due_date.overdue?).to be false
        end
      end

      context 'when due date is exactly now' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: Time.current + 1.seconds,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns false' do
          expect(due_date.overdue?).to be false
        end
      end
    end

    describe '#upcoming?' do
      context 'when due date is in the future' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 1.day.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns true' do
          expect(due_date.upcoming?).to be true
        end
      end

      context 'when due date is in the past' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 1.day.ago,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns false' do
          expect(due_date.upcoming?).to be false
        end
      end
    end

    describe '#set' do
      let(:due_date) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      context 'when updating all fields' do
        before do
          due_date.set(review_type.id, assignment2.id, 2)
          due_date.reload
        end

        it 'updates deadline_type_id' do
          expect(due_date.deadline_type_id).to eq(review_type.id)
        end

        it 'updates parent_id' do
          expect(due_date.parent_id).to eq(assignment2.id)
        end

        it 'updates round' do
          expect(due_date.round).to eq(2)
        end

        it 'persists changes to database' do
          expect(due_date.reload.round).to eq(2)
        end
      end

      context 'when called with invalid data' do
        it 'raises error for non-existent deadline_type_id' do
          expect do
            due_date.set(99_999, assignment2.id, 1)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    describe '#copy' do
      let(:original) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: late_right.id,
          round: 1
        )
      end

      let(:copied) { original.copy(assignment2.id) }

      it 'creates a new persisted record' do
        expect(copied).to be_persisted
      end

      it 'has different id from original' do
        expect(copied.id).not_to eq(original.id)
      end

      it 'copies to new parent' do
        expect(copied.parent_id).to eq(assignment2.id)
      end

      it 'preserves due_at' do
        expect(copied.due_at).to eq(original.due_at)
      end

      it 'preserves deadline_type_id' do
        expect(copied.deadline_type_id).to eq(original.deadline_type_id)
      end

      it 'preserves submission_allowed_id' do
        expect(copied.submission_allowed_id).to eq(original.submission_allowed_id)
      end

      it 'preserves review_allowed_id' do
        expect(copied.review_allowed_id).to eq(original.review_allowed_id)
      end

      it 'preserves round' do
        expect(copied.round).to eq(original.round)
      end

      context 'when copying to non-existent assignment' do
        it 'raises error' do
          expect do
            original.copy(99_999)
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe '#deadline_type_name' do
      let(:due_date) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'returns the name of associated deadline type' do
        expect(due_date.deadline_type_name).to eq('submission')
      end

      context 'when deadline_type is nil' do
        before { allow(due_date).to receive(:deadline_type).and_return(nil) }

        it 'returns nil' do
          expect(due_date.deadline_type_name).to be_nil
        end
      end
    end

    describe '#last_deadline?' do
      context 'when this is the last deadline' do
        let(:last_deadline) do
          DueDate.create(
            parent: assignment,
            due_at: 5.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns true' do
          expect(last_deadline.last_deadline?).to be true
        end
      end

      context 'when there are later deadlines' do
        let!(:earlier_deadline) do
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        let!(:later_deadline) do
          DueDate.create(
            parent: assignment,
            due_at: 5.days.from_now,
            deadline_type: review_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns false' do
          expect(earlier_deadline.last_deadline?).to be false
        end
      end

      context 'when parent has no other due dates' do
        let(:only_deadline) do
          DueDate.create(
            parent: assignment2,
            due_at: 3.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'returns true' do
          expect(only_deadline.last_deadline?).to be true
        end
      end
    end

    describe '#<=>' do
      let(:earlier) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      let(:later) do
        DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'returns -1 when comparing earlier to later' do
        expect(earlier <=> later).to eq(-1)
      end

      it 'returns 1 when comparing later to earlier' do
        expect(later <=> earlier).to eq(1)
      end

      it 'returns 0 when comparing to itself' do
        expect(earlier <=> earlier).to eq(0)
      end

      context 'when comparing with non-DueDate object' do
        it 'returns nil' do
          expect(earlier <=> 'not a due date').to be_nil
        end
      end
    end
  end

  describe 'class methods' do
    describe '.sort_due_dates' do
      let!(:due_date1) do
        DueDate.create(
          parent: assignment,
          due_at: 5.days.from_now,
          deadline_type: submission_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      let!(:due_date2) do
        DueDate.create(
          parent: assignment,
          due_at: 2.days.from_now,
          deadline_type: review_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      let!(:due_date3) do
        DueDate.create(
          parent: assignment,
          due_at: 1.day.ago,
          deadline_type: quiz_type,
          submission_allowed_id: ok_right.id,
          review_allowed_id: ok_right.id
        )
      end

      it 'sorts due dates from earliest to latest' do
        sorted = DueDate.sort_due_dates([due_date1, due_date2, due_date3])
        expect(sorted).to eq([due_date3, due_date2, due_date1])
      end

      context 'when array is empty' do
        it 'returns empty array' do
          expect(DueDate.sort_due_dates([])).to eq([])
        end
      end

      context 'when array has single element' do
        it 'returns array with single element' do
          expect(DueDate.sort_due_dates([due_date1])).to eq([due_date1])
        end
      end
    end

    describe '.any_future_due_dates?' do
      context 'when future due dates exist' do
        let(:due_dates) do
          [
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
        end

        it 'returns true' do
          expect(DueDate.any_future_due_dates?(due_dates)).to be true
        end
      end

      context 'when no future due dates exist' do
        let(:due_dates) do
          [
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
        end

        it 'returns false' do
          expect(DueDate.any_future_due_dates?(due_dates)).to be false
        end
      end

      context 'when array is empty' do
        it 'returns false' do
          expect(DueDate.any_future_due_dates?([])).to be false
        end
      end

      context 'when mix of past and future dates' do
        let(:due_dates) do
          [
            DueDate.create(
              parent: assignment,
              due_at: 2.days.ago,
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
        end

        it 'returns true' do
          expect(DueDate.any_future_due_dates?(due_dates)).to be true
        end
      end
    end

    describe '.copy' do
      before do
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
      end

      let(:original_count) { assignment.due_dates.count }

      it 'creates due dates for target assignment' do
        expect { DueDate.copy(assignment.id, assignment2.id) }
          .to change { assignment2.due_dates.count }.from(0).to(original_count)
      end

      it 'preserves original assignment due dates' do
        expect { DueDate.copy(assignment.id, assignment2.id) }
          .not_to(change { assignment.due_dates.count })
      end

      it 'copies all attributes correctly' do
        DueDate.copy(assignment.id, assignment2.id)

        assignment.due_dates.each_with_index do |original, index|
          copied = assignment2.due_dates[index]
          expect(copied.due_at).to eq(original.due_at)
          expect(copied.deadline_type_id).to eq(original.deadline_type_id)
          expect(copied.round).to eq(original.round)
        end
      end

      context 'when source assignment has no due dates' do
        before { assignment.due_dates.destroy_all }

        it 'does not create any due dates' do
          expect { DueDate.copy(assignment.id, assignment2.id) }
            .not_to(change { assignment2.due_dates.count })
        end
      end

      context 'when source assignment does not exist' do
        it 'raises error' do
          expect { DueDate.copy(99_999, assignment2.id) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when target assignment does not exist' do
        it 'raises error' do
          expect { DueDate.copy(assignment.id, 99_999) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'callbacks' do
    describe 'before_save :set_default_round' do
      context 'when round is not specified' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id
          )
        end

        it 'sets round to 1' do
          expect(due_date.round).to eq(1)
        end
      end

      context 'when round is explicitly set' do
        let(:due_date) do
          DueDate.create(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: 3
          )
        end

        it 'does not override the value' do
          expect(due_date.round).to eq(3)
        end
      end

      context 'when round is set to nil explicitly' do
        let(:due_date) do
          DueDate.new(
            parent: assignment,
            due_at: 2.days.from_now,
            deadline_type: submission_type,
            submission_allowed_id: ok_right.id,
            review_allowed_id: ok_right.id,
            round: nil
          )
        end

        it 'sets default value before save' do
          due_date.save
          expect(due_date.round).to eq(1)
        end
      end
    end
  end
end
