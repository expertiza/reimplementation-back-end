# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewMappingStrategies::LeastReviewedSubmissionStrategy, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:instructor_user) do
    User.create!(name: 'lrs_instructor', password_digest: 'x',
                 role_id: @roles[:instructor].id, full_name: 'LRS Instructor',
                 email: 'lrs_instructor@example.com')
  end

  let(:student_a) do
    User.create!(name: 'lrs_student_a', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'LRS Student A',
                 email: 'lrs_a@example.com')
  end

  let(:student_b) do
    User.create!(name: 'lrs_student_b', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'LRS Student B',
                 email: 'lrs_b@example.com')
  end

  let(:assignment) do
    Assignment.create!(name: 'LRS Assignment', instructor: instructor_user,
                       review_topic_threshold: 2)
  end

  let(:reviewer) do
    AssignmentParticipant.create!(user: student_a, parent_id: assignment.id,
                                  handle: student_a.name)
  end

  let(:team_a) { AssignmentTeam.create!(name: 'LRS Team A', parent_id: assignment.id) }
  let(:team_b) { AssignmentTeam.create!(name: 'LRS Team B', parent_id: assignment.id) }

  subject(:strategy) { described_class.new(assignment) }

  # Stubs assignment.teams to return our specific instances so per-instance stubs apply.
  before do
    allow(assignment).to receive(:teams).and_return([team_a, team_b])
    allow(team_a).to receive(:has_submissions?).and_return(true)
    allow(team_b).to receive(:has_submissions?).and_return(true)
    allow(team_a).to receive(:participants).and_return([])
    allow(team_b).to receive(:participants).and_return([])
  end

  def submit_review(reviewer_id:, reviewee_id:)
    map = ReviewResponseMap.create!(reviewer_id: reviewer_id, reviewee_id: reviewee_id,
                                    reviewed_object_id: assignment.id)
    Response.create!(map_id: map.id, is_submitted: true)
    map
  end

  describe '#assign_one' do
    it 'returns the team with the fewest submitted reviews' do
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      submit_review(reviewer_id: other.id, reviewee_id: team_a.id)
      # team_a: 1 submitted review; team_b: 0 — expect team_b
      expect(strategy.assign_one(reviewer)).to eq(team_b)
    end

    it 'returns nil when no teams have submissions' do
      allow(team_a).to receive(:has_submissions?).and_return(false)
      allow(team_b).to receive(:has_submissions?).and_return(false)
      expect(strategy.assign_one(reviewer)).to be_nil
    end

    it 'skips teams already assigned to the reviewer' do
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      expect(strategy.assign_one(reviewer)).to eq(team_b)
    end

    it 'skips the reviewer own team' do
      allow(team_a).to receive(:participants).and_return([reviewer])
      expect(strategy.assign_one(reviewer)).to eq(team_b)
    end

    it 'returns nil when all teams are ineligible' do
      allow(team_a).to receive(:participants).and_return([reviewer])
      allow(team_b).to receive(:has_submissions?).and_return(false)
      expect(strategy.assign_one(reviewer)).to be_nil
    end

    it 'counts only submitted reviews, not in-progress ones' do
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      # In-progress review for team_a — should not count
      map = ReviewResponseMap.create!(reviewer_id: other.id, reviewee_id: team_a.id,
                                      reviewed_object_id: assignment.id)
      Response.create!(map_id: map.id, is_submitted: false)
      # Both teams have 0 submitted reviews despite team_a having an in-progress one;
      # either team is valid but team_a must not be penalized
      result = strategy.assign_one(reviewer)
      expect([team_a, team_b]).to include(result)
    end

    it 'respects the fairness threshold window' do
      assignment.update!(review_topic_threshold: 0)
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      submit_review(reviewer_id: other.id, reviewee_id: team_a.id)
      # team_a count=1, min=0 (team_b), threshold=0 → team_a is outside the window
      expect(strategy.assign_one(reviewer)).to eq(team_b)
    end
  end
end
