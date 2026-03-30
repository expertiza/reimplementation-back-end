# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskOrdering::ReviewTask do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_rvt",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor RVT",
      email: "instructor_rvt@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_rvt",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student RVT",
      email: "student_rvt@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "RVT Assignment", instructor: instructor) }
  let!(:participant) do
    AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
  end
  let!(:team) { AssignmentTeam.create!(name: "RVT Team", parent_id: assignment.id) }
  let!(:teams_participant) { TeamsParticipant.create!(team: team, participant: participant, user: student) }

  let!(:review_map) do
    map = ReviewResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: participant.id,
        reviewed_object_id: assignment.id
        )
        map.save!(validate: false)
        map
    end

  subject(:task) do
    TaskOrdering::ReviewTask.new(
      assignment: assignment,
      team_participant: teams_participant,
      review_map: review_map
    )
  end

  describe '#task_type' do
    it 'returns :review' do
      expect(task.task_type).to eq(:review)
    end
  end

  describe '#response_map' do
    it 'returns the review map' do
      expect(task.response_map).to eq(review_map)
    end
  end

  describe '#completed?' do
    it 'returns false when no submitted response exists' do
      expect(task.completed?).to be false
    end

    it 'returns true when a submitted response exists' do
      Response.create!(map_id: review_map.id, round: 1, is_submitted: true)
      expect(task.completed?).to be true
    end

    it 'returns false when response exists but not submitted' do
      Response.create!(map_id: review_map.id, round: 1, is_submitted: false)
      expect(task.completed?).to be false
    end
  end

  describe '#ensure_response!' do
    it 'creates a response if none exists' do
      expect { task.ensure_response! }.to change(Response, :count).by(1)
    end

    it 'does not duplicate responses' do
      task.ensure_response!
      expect { task.ensure_response! }.not_to change(Response, :count)
    end

    it 'creates response with is_submitted false' do
      task.ensure_response!
      expect(Response.last.is_submitted).to be false
    end
  end

  describe '#to_task_hash' do
    it 'includes correct task_type' do
      expect(task.to_task_hash[:task_type]).to eq(:review)
    end

    it 'includes correct response_map_id' do
      expect(task.to_task_hash[:response_map_id]).to eq(review_map.id)
    end

    it 'includes correct assignment_id' do
      expect(task.to_task_hash[:assignment_id]).to eq(assignment.id)
    end
  end
end