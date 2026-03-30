# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskOrdering::TaskQueue do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_tq",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor TQ",
      email: "instructor_tq@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_tq",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student TQ",
      email: "student_tq@example.com"
    )
  end

  let!(:assignment) { Assignment.create!(name: "TQ Assignment", instructor: instructor) }
  let!(:participant) do
    AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name)
  end
  let!(:team) { AssignmentTeam.create!(name: "TQ Team", parent_id: assignment.id) }
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

  subject(:queue) { TaskOrdering::TaskQueue.new(assignment, teams_participant) }

  describe '#map_ids' do
    it 'returns an array' do
      expect(queue.map_ids).to be_an(Array)
    end

    it 'includes the review map id' do
      expect(queue.map_ids).to include(review_map.id)
    end

    it 'places quiz map ids before review map ids' do
      quiz_map = QuizResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: participant.id,
        reviewed_object_id: assignment.id
      )
      quiz_map.save!(validate: false)
      ids = queue.map_ids
      expect(ids.first).to eq(quiz_map.id)
      expect(ids.last).to eq(review_map.id)
    end
  end

  describe '#map_in_queue?' do
    it 'returns true for a map in the queue' do
      expect(queue.map_in_queue?(review_map.id)).to be true
    end

    it 'returns false for a map not in the queue' do
      expect(queue.map_in_queue?(99999)).to be false
    end

    it 'handles string map ids' do
      expect(queue.map_in_queue?(review_map.id.to_s)).to be true
    end
  end

  describe '#prior_tasks_complete_for?' do
    it 'returns false for unknown map id' do
      expect(queue.prior_tasks_complete_for?(99999)).to be false
    end

    it 'returns true when map is the only item in queue' do
      expect(queue.prior_tasks_complete_for?(review_map.id)).to be true
    end

    it 'returns false when prior quiz task is not submitted' do
      quiz_map = QuizResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: participant.id,
        reviewed_object_id: assignment.id
      )
      quiz_map.save!(validate: false)
      expect(queue.prior_tasks_complete_for?(review_map.id)).to be false
    end

    it 'returns true when prior quiz task is submitted' do
      quiz_map = QuizResponseMap.new(
        reviewer_id: participant.id,
        reviewee_id: participant.id,
        reviewed_object_id: assignment.id
      )
      quiz_map.save!(validate: false)
      Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
      expect(queue.prior_tasks_complete_for?(review_map.id)).to be true
    end
  end
end