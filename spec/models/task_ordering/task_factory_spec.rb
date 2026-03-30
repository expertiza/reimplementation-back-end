# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskOrdering::TaskFactory do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_tf",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor TF",
      email: "instructor_tf@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_tf",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student TF",
      email: "student_tf@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "TF Assignment", instructor: instructor) }
  let!(:participant) do
    AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
  end
  let!(:team) { AssignmentTeam.create!(name: "TF Team", parent_id: assignment.id) }
  let!(:teams_participant) { TeamsParticipant.create!(team: team, participant: participant, user: student) }

  describe '.build' do
    context 'with no review maps and no quiz' do
      before { allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }

      it 'returns an empty array' do
        tasks = TaskOrdering::TaskFactory.build(assignment: assignment, team_participant: teams_participant)
        expect(tasks).to be_an(Array)
        expect(tasks).to be_empty
      end
    end

    context 'with a review map and reviewer duty' do
      let!(:duty) { Duty.create!(name: 'reviewer', instructor_id: instructor.id) }
      let!(:review_map) do
        map = ReviewResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: participant.id,
        reviewed_object_id: assignment.id
        )
        map.save!(validate: false)
        map
    end

      before do
        teams_participant.update!(duty_id: duty.id)
        allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
      end

      it 'returns a ReviewTask' do
        tasks = TaskOrdering::TaskFactory.build(assignment: assignment, team_participant: teams_participant)
        expect(tasks.map(&:task_type)).to include(:review)
      end
    end
  end

  describe '.allows_review?' do
    it 'returns true for reviewer' do
      expect(described_class.allows_review?(Duty.new(name: 'reviewer'))).to be true
    end

    it 'returns true for participant' do
      expect(described_class.allows_review?(Duty.new(name: 'participant'))).to be true
    end

    it 'returns true for reader' do
      expect(described_class.allows_review?(Duty.new(name: 'reader'))).to be true
    end

    it 'returns true for mentor' do
      expect(described_class.allows_review?(Duty.new(name: 'mentor'))).to be true
    end

    it 'returns false for submitter' do
      expect(described_class.allows_review?(Duty.new(name: 'submitter'))).to be false
    end

    it 'returns false for nil' do
      expect(described_class.allows_review?(nil)).to be false
    end
  end

  describe '.allows_quiz?' do
    it 'returns true for participant' do
      expect(described_class.allows_quiz?(Duty.new(name: 'participant'))).to be true
    end

    it 'returns true for reader' do
      expect(described_class.allows_quiz?(Duty.new(name: 'reader'))).to be true
    end

    it 'returns true for mentor' do
      expect(described_class.allows_quiz?(Duty.new(name: 'mentor'))).to be true
    end

    it 'returns false for reviewer' do
      expect(described_class.allows_quiz?(Duty.new(name: 'reviewer'))).to be false
    end

    it 'returns false for submitter' do
      expect(described_class.allows_quiz?(Duty.new(name: 'submitter'))).to be false
    end

    it 'returns false for nil' do
      expect(described_class.allows_quiz?(nil)).to be false
    end
  end

  describe '.allows_submit?' do
    it 'returns true for submitter' do
      expect(described_class.allows_submit?(Duty.new(name: 'submitter'))).to be true
    end

    it 'returns true for participant' do
      expect(described_class.allows_submit?(Duty.new(name: 'participant'))).to be true
    end

    it 'returns true for mentor' do
      expect(described_class.allows_submit?(Duty.new(name: 'mentor'))).to be true
    end

    it 'returns false for reviewer' do
      expect(described_class.allows_submit?(Duty.new(name: 'reviewer'))).to be false
    end

    it 'returns false for reader' do
      expect(described_class.allows_submit?(Duty.new(name: 'reader'))).to be false
    end

    it 'returns false for nil' do
      expect(described_class.allows_submit?(nil)).to be false
    end
  end
end