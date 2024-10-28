# spec/models/due_date_spec.rb
require 'rails_helper'

RSpec.describe DueDate, type: :model do
  let(:role) { Role.create(name: Administrator, parent_id: nil) }
  let(:instructor) do
    Instructor.create(name: 'testinstructor', full_name: 'testinstructor', email: 'test@test.com', password: '123456',
                      role:, role_id: role.id)
  end
  describe '.get_next_due_date' do
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

      it 'calls AssignmentDueDate.next_due_date' do
        expect(AssignmentDueDate).to receive(:next_due_date).with(assignment_due_date1.parent_id)
        DueDate.next_due_date(assignment_due_date1.parent_id, assignment_due_date1.parent_type)
      end

      it 'returns the next upcoming due date' do
        result = DueDate.next_due_date(assignment_due_date2.parent_id, assignment_due_date2.parent_type)
        expect(result).to eq(assignment_due_date1)
      end
    end

    context 'when parent_type is SignUpTopic' do
      let!(:assignment) { Assignment.create!(id: 2, name: 'Test Assignment', instructor:) }
      let!(:topic) { SignUpTopic.create!(id: 2, topic_name: 'Test Topic', assignment:) }
      let!(:topic_due_date1) do
        DueDate.create(parent: topic, due_at: 2.days.from_now, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:topic_due_date2) do
        DueDate.create(parent: topic, due_at: 3.days.from_now, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end
      let!(:past_topic_due_date) do
        DueDate.create(parent: topic, due_at: 1.day.ago, submission_allowed_id: 3, review_allowed_id: 3,
                       deadline_type_id: 3, type: 'TopicDueDate')
      end

      it 'calls TopicDueDate.get_next_due_date' do
        expect(TopicDueDate).to receive(:get_next_due_date).with(topic_due_date1.parent.assignment,
                                                                 topic_due_date1.type)
        DueDate.get_next_due_date
      end

      it 'returns the next upcoming due date for topics' do
        STDOUT.puts instructor, role, assignment, topic, topic_due_date1, topic_due_date2
        result = DueDate.next_due_date(topic_due_date2.parent_id, topic_due_date2.type)
        expect(result).to eq(topic_due_date1)
      end
    end
  end

  describe '#due_at validation' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }

    it 'is invalid without a parent, due_at, submission_allowed_id, review_allowed_id, or deadline_type_id' do
      due_date1 = DueDate.new(parent: nil, due_at: 2.days.from_now)
      expect(due_date1).to be_invalid

      due_date2 = DueDate.new(parent: assignment, due_at: nil)
      expect(due_date2).to be_invalid
    end

    it 'is valid with a due_at' do
      due_date = DueDate.new(parent: assignment, due_at: 2.days.from_now)
      expect(due_date).to be_valid
    end
  end
end
