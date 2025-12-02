# frozen_string_literal: true

# spec/models/due_date_spec.rb
require 'rails_helper'

RSpec.describe DueDate, type: :model do
  let(:role) {Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil)}
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role: role) }

  describe '.fetch_due_dates' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }

    it 'fetches all the due_dates from a due_date\'s parent' do
      due_date1 = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date2 = DueDate.create(parent: assignment, due_at: 3.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date3 = DueDate.create(parent: assignment, due_at: 4.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date4 = DueDate.create(parent: assignment, due_at: 2.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date5 = DueDate.create(parent: assignment, due_at: 3.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_dates = [due_date1, due_date2, due_date3, due_date4, due_date5]
      fetched_due_dates = DueDate.fetch_due_dates(due_date3.parent_id)

      fetched_due_dates.each { |due_date| expect(due_dates).to include(due_date) }
    end
  end

  describe '.sort_due_dates' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
    it 'sorts a list of due dates from earliest to latest' do
      due_date1 = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date2 = DueDate.create(parent: assignment, due_at: 3.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date3 = DueDate.create(parent: assignment, due_at: 4.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date4 = DueDate.create(parent: assignment, due_at: 2.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date5 = DueDate.create(parent: assignment, due_at: 3.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      sorted_dates = DueDate.sort_due_dates([due_date1, due_date2, due_date3, due_date4, due_date5])

      expect(sorted_dates).to eq([due_date5, due_date4, due_date1, due_date2, due_date3])
    end
  end

  describe '.any_future_due_dates?' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
    it 'returns true when a future due date exists' do
      due_date1 = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date2 = DueDate.create(parent: assignment, due_at: 3.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date3 = DueDate.create(parent: assignment, due_at: 4.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_dates = [due_date1, due_date2, due_date3]
      expect(DueDate.any_future_due_dates?(due_dates)).to(be true)
    end

    it 'returns true when a no future due dates exist' do
      due_date1 = DueDate.create(parent: assignment, due_at: 2.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date2 = DueDate.create(parent: assignment, due_at: 3.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date3 = DueDate.create(parent: assignment, due_at: 4.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_dates = [due_date1, due_date2, due_date3]
      expect(DueDate.any_future_due_dates?(due_dates)).to(be false)
    end
  end

  describe '.set' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
    let(:assignment2) { Assignment.create(id: 2, name: 'Test Assignment2', instructor:) }
    it 'returns true when a future due date exists' do
      due_date = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                review_allowed_id: 3, deadline_type_id: 3)
      expect(due_date.deadline_type_id).to(be 3)
      expect(due_date.parent).to(be assignment)
      expect(due_date.round).to(be nil)

      due_date.set(1, assignment2.id, 1)

      expect(due_date.deadline_type_id).to(be 1)
      expect(due_date.parent).to eq(assignment2)
      expect(due_date.round).to(be 1)
    end
  end

  describe '.copy' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
    let(:assignment2) { Assignment.create(id: 2, name: 'Test Assignment2', instructor:) }
    it 'copies the due dates from one assignment to another' do
      due_date1 = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date2 = DueDate.create(parent: assignment, due_at: 3.days.from_now, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)
      due_date3 = DueDate.create(parent: assignment, due_at: 3.days.ago, submission_allowed_id: 3,
                                 review_allowed_id: 3, deadline_type_id: 3)

      assign1_due_dates = DueDate.fetch_due_dates(assignment.id)
      assign1_due_dates.each { |due_date| due_date.copy(assignment2.id) }
      assign2_due_dates = DueDate.fetch_due_dates(assignment2.id)

      excluded_attributes = %w[id created_at updated_at parent parent_id]

      assign1_due_dates.zip(assign2_due_dates).each do |original, copy|
        original_attributes = original.attributes.except(*excluded_attributes)
        copied_attributes = copy.attributes.except(*excluded_attributes)

        expect(copied_attributes).to eq(original_attributes)
      end
    end
  end

  describe '.next_due_date' do
    context 'when parent_type is Assignment' do
      let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
      let!(:assignment_due_date1) do
        DueDate.create(parent: assignment, due_at: 2.days.from_now,
                       submission_allowed_id: 3, review_allowed_id: 3, deadline_type_id: 3)
      end
      let!(:assignment_due_date2) do
        DueDate.create(parent: assignment, due_at: 3.days.from_now,
                       submission_allowed_id: 3, review_allowed_id: 3, deadline_type_id: 3)
      end
      let!(:assignment_past_due_date) do
        DueDate.create(parent: assignment, due_at: 1.day.ago,
                       submission_allowed_id: 3, review_allowed_id: 3, deadline_type_id: 3)
      end

      it 'returns the next upcoming due date' do
        result = DueDate.next_due_date(assignment_due_date2.parent_id)
        expect(result).to eq(assignment_due_date1)
      end
    end

    context 'when parent_type is SignUpTopic' do
      let!(:assignment) { Assignment.create!(id: 2, name: 'Test Assignment', instructor:) }
      let!(:assignment2) { Assignment.create(id: 6, name: 'Test Assignment2', instructor:) }
      let!(:topic1) { SignUpTopic.create!(id: 2, topic_name: 'Test Topic', assignment:) }
      let!(:topic2) { SignUpTopic.create(id: 4, topic_name: 'Test Topic2', assignment: assignment2) }
      let!(:topic3) { SignUpTopic.create(id: 5, topic_name: 'Test Topic2', assignment: assignment2) }
      let!(:topic_due_date1) do
        DueDate.create(parent: topic1, due_at: 2.days.from_now, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:topic_due_date2) do
        DueDate.create(parent: topic1, due_at: 3.days.from_now, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:past_topic_due_date) do
        DueDate.create(parent: topic1, due_at: 1.day.ago, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:past_topic_due_date2) do
        DueDate.create(parent: topic2, due_at: 2.day.ago, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:assignment_due_date) do
        DueDate.create(parent: assignment2, due_at: 2.days.from_now, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'AssignmentDueDate')
      end

      it 'calls TopicDueDate.next_due_date' do
        expect(TopicDueDate).to receive(:next_due_date).with(topic_due_date1.parent.assignment.id,
                                                             topic_due_date1.parent_id)
        TopicDueDate.next_due_date(topic_due_date1.parent.assignment.id, topic_due_date1.parent_id)
      end

      it 'returns the next upcoming due date for topics' do
        result = TopicDueDate.next_due_date(topic_due_date2.parent.assignment.id, topic_due_date2.parent_id)
        expect(result).to eq(topic_due_date1)
      end

      it 'returns the next assignment due date when topic has no upcoming due dates' do
        result = TopicDueDate.next_due_date(past_topic_due_date2.parent.assignment.id, past_topic_due_date2.parent_id)

        expect(result).to eq(assignment_due_date)
      end
    end
  end

  describe 'validation' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }

    it 'is invalid without a parent' do
      due_date = DueDate.create(parent: nil, due_at: 2.days.from_now, submission_allowed_id: 3,
                                review_allowed_id: 3, deadline_type_id: 3)
      expect(due_date).to be_invalid
    end

    it 'is invalid without a due_at' do
      due_date = DueDate.create(parent: assignment, due_at: nil, submission_allowed_id: 3,
                                review_allowed_id: 3, deadline_type_id: 3)
      expect(due_date).to be_invalid
    end

    it 'is valid with required fields' do
      due_date = DueDate.create(parent: assignment, due_at: 2.days.from_now, submission_allowed_id: 3,
                                review_allowed_id: 3, deadline_type_id: 3)
      expect(due_date).to be_valid
    end
  end
end
