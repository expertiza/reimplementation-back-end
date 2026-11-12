# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewMappingStrategies::LeastReviewedTopicStrategy, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:instructor_user) do
    User.create!(name: 'lrt_instructor', password_digest: 'x',
                 role_id: @roles[:instructor].id, full_name: 'LRT Instructor',
                 email: 'lrt_instructor@example.com')
  end

  let(:student_a) do
    User.create!(name: 'lrt_student_a', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'LRT Student A',
                 email: 'lrt_a@example.com')
  end

  let(:student_b) do
    User.create!(name: 'lrt_student_b', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'LRT Student B',
                 email: 'lrt_b@example.com')
  end

  let(:assignment) do
    Assignment.create!(name: 'LRT Assignment', instructor: instructor_user,
                       review_topic_threshold: 1)
  end

  let(:reviewer) do
    AssignmentParticipant.create!(user: student_a, parent_id: assignment.id,
                                  handle: student_a.name)
  end

  let(:topic_a) { ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'LRT Topic A') }
  let(:topic_b) { ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'LRT Topic B') }
  let(:team_a)  { AssignmentTeam.create!(name: 'LRT Team A', parent_id: assignment.id) }
  let(:team_b)  { AssignmentTeam.create!(name: 'LRT Team B', parent_id: assignment.id) }

  subject(:strategy) { described_class.new(assignment) }

  # Stubs assignment.teams and topic.teams so our specific instances are used
  # throughout — this ensures per-instance stubs (participants, etc.) apply correctly.
  before do
    SignedUpTeam.create!(project_topic: topic_a, team: team_a)
    SignedUpTeam.create!(project_topic: topic_b, team: team_b)
    allow(assignment).to receive(:teams).and_return([team_a, team_b])
    allow(topic_a).to receive(:teams).and_return([team_a])
    allow(topic_b).to receive(:teams).and_return([team_b])
    allow(team_a).to receive(:participants).and_return([])
    allow(team_b).to receive(:participants).and_return([])
  end

  def submit_review(reviewer_id:, reviewee_id:)
    map = ReviewResponseMap.create!(reviewer_id: reviewer_id, reviewee_id: reviewee_id,
                                    reviewed_object_id: assignment.id)
    Response.create!(map_id: map.id, is_submitted: true)
    map
  end

  describe '#assign_one with automatic topic selection' do
    it 'returns a team on the topic with the fewest submitted reviews' do
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      submit_review(reviewer_id: other.id, reviewee_id: team_a.id)
      # topic_a: 1 submitted review; topic_b: 0 — should pick topic_b's team
      expect(strategy.assign_one(reviewer)).to eq(team_b)
    end

    it 'returns nil when no topics have teams' do
      SignedUpTeam.destroy_all
      expect(strategy.assign_one(reviewer)).to be_nil
    end

    it 'returns nil when all teams are already assigned to the reviewer' do
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_b.id,
                                reviewed_object_id: assignment.id)
      expect(strategy.assign_one(reviewer)).to be_nil
    end
  end

  describe '#assign_one with explicit topic' do
    it 'assigns a team on the specified topic' do
      expect(strategy.assign_one(reviewer, topic: topic_a)).to eq(team_a)
    end

    it 'returns nil when all teams on the topic are already assigned to the reviewer' do
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      expect(strategy.assign_one(reviewer, topic: topic_a)).to be_nil
    end
  end

  describe 'self-review exclusion' do
    it 'does not assign the reviewer to their own team' do
      allow(team_a).to receive(:participants).and_return([reviewer])
      expect(strategy.assign_one(reviewer, topic: topic_a)).to be_nil
    end
  end

  describe 'fairness threshold window' do
    it 'excludes a team whose submitted count exceeds global_min + threshold' do
      assignment.update!(review_topic_threshold: 0)
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      submit_review(reviewer_id: other.id, reviewee_id: team_a.id)
      # team_a count=1 > global_min(0, from team_b) + threshold(0) → excluded
      expect(strategy.assign_one(reviewer, topic: topic_a)).to be_nil
    end

    it 'includes a team within the threshold window' do
      assignment.update!(review_topic_threshold: 2)
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      submit_review(reviewer_id: other.id, reviewee_id: team_a.id)
      # team_a count=1 <= global_min(0) + threshold(2) → still eligible
      expect(strategy.assign_one(reviewer, topic: topic_a)).to eq(team_a)
    end

    it 'uses the assignment-wide minimum, not the topic-local minimum' do
      assignment.update!(review_topic_threshold: 0)
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      # Give team_b a submitted review so global_min rises to 1
      submit_review(reviewer_id: other.id, reviewee_id: team_b.id)
      # team_a count=0, global_min=0 (team_a itself), threshold=0 → 0 <= 0+0 → eligible
      expect(strategy.assign_one(reviewer, topic: topic_a)).to eq(team_a)
    end
  end
end
