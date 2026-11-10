# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewAllocator, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:instructor_user) do
    User.create!(name: 'alloc_instructor', password_digest: 'x',
                 role_id: @roles[:instructor].id, full_name: 'Alloc Instructor',
                 email: 'alloc_instructor@example.com')
  end

  let(:student_a) do
    User.create!(name: 'alloc_student_a', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'Alloc Student A',
                 email: 'alloc_a@example.com')
  end

  let(:student_b) do
    User.create!(name: 'alloc_student_b', password_digest: 'x',
                 role_id: @roles[:student].id, full_name: 'Alloc Student B',
                 email: 'alloc_b@example.com')
  end

  let(:assignment) do
    Assignment.create!(name: 'Alloc Assignment', instructor: instructor_user,
                       review_topic_threshold: 1, num_reviews_allowed: 3)
  end

  let(:reviewer) do
    AssignmentParticipant.create!(user: student_a, parent_id: assignment.id,
                                  handle: student_a.name)
  end

  let(:team_a) { AssignmentTeam.create!(name: 'Alloc Team A', parent_id: assignment.id) }
  let(:team_b) { AssignmentTeam.create!(name: 'Alloc Team B', parent_id: assignment.id) }

  subject(:allocator) { ReviewAllocator.new(assignment) }

  def submit_review(reviewer_id:, reviewee_id:)
    map = ReviewResponseMap.create!(reviewer_id: reviewer_id, reviewee_id: reviewee_id,
                                    reviewed_object_id: assignment.id)
    Response.create!(map_id: map.id, is_submitted: true)
    map
  end

  describe '#can_accept_more_reviews?' do
    it 'returns true when no cap is configured' do
      assignment.update!(num_reviews_allowed: nil)
      expect(allocator.can_accept_more_reviews?(reviewer)).to be true
    end

    it 'returns true when reviewer is under the cap' do
      expect(allocator.can_accept_more_reviews?(reviewer)).to be true
    end

    it 'returns false when reviewer has reached the cap' do
      assignment.update!(num_reviews_allowed: 1)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      expect(allocator.can_accept_more_reviews?(reviewer)).to be false
    end
  end

  describe '#assign_dynamically' do
    it 'returns nil when reviewer is at the cap' do
      assignment.update!(num_reviews_allowed: 1)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      strategy = ReviewMappingStrategies::LeastReviewedSubmissionStrategy
      expect(allocator.assign_dynamically(strategy, reviewer)).to be_nil
    end

    it 'returns nil when strategy finds no eligible team' do
      strategy_instance = instance_double(ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
                                          assign_one: nil)
      allow(ReviewMappingStrategies::LeastReviewedSubmissionStrategy)
        .to receive(:new).and_return(strategy_instance)
      expect(allocator.assign_dynamically(ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
                                          reviewer)).to be_nil
    end

    it 'creates and returns a mapping when strategy returns a team' do
      strategy_instance = instance_double(ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
                                          assign_one: team_a)
      allow(ReviewMappingStrategies::LeastReviewedSubmissionStrategy)
        .to receive(:new).and_return(strategy_instance)
      mapping = allocator.assign_dynamically(ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
                                             reviewer)
      expect(mapping).to be_a(ReviewResponseMap)
      expect(mapping.reviewee_id).to eq(team_a.id)
    end
  end

  describe '#delete_review_mapping' do
    it 'destroys the mapping by id' do
      map = ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                      reviewed_object_id: assignment.id)
      expect { allocator.delete_review_mapping(map.id) }
        .to change(ReviewResponseMap, :count).by(-1)
    end
  end

  describe '#delete_all_reviews_by' do
    it 'destroys all mappings for the reviewer on this assignment' do
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_b.id,
                                reviewed_object_id: assignment.id)
      expect { allocator.delete_all_reviews_by(reviewer) }
        .to change(ReviewResponseMap, :count).by(-2)
    end

    it 'does not delete mappings belonging to other reviewers' do
      other = AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                            handle: student_b.name)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                reviewed_object_id: assignment.id)
      ReviewResponseMap.create!(reviewer_id: other.id, reviewee_id: team_b.id,
                                reviewed_object_id: assignment.id)
      expect { allocator.delete_all_reviews_by(reviewer) }
        .to change(ReviewResponseMap, :count).by(-1)
    end
  end

  describe '#calibration_reviews_for' do
    it 'returns only calibration mappings for the reviewer' do
      cal_map = ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_a.id,
                                          reviewed_object_id: assignment.id, for_calibration: true)
      ReviewResponseMap.create!(reviewer_id: reviewer.id, reviewee_id: team_b.id,
                                reviewed_object_id: assignment.id, for_calibration: false)
      result = allocator.calibration_reviews_for(reviewer)
      expect(result).to include(cal_map)
      expect(result.count).to eq(1)
    end
  end

  describe '#eligible_topics' do
    let(:other_reviewer) do
      AssignmentParticipant.create!(user: student_b, parent_id: assignment.id,
                                    handle: student_b.name)
    end
    let(:topic_a) { ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'Alloc Topic A') }
    let(:topic_b) { ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'Alloc Topic B') }

    before do
      SignedUpTeam.create!(project_topic: topic_a, team: team_a)
      SignedUpTeam.create!(project_topic: topic_b, team: team_b)
    end

    it 'returns all topics within the threshold window' do
      topics, _min = allocator.eligible_topics(reviewer)
      ids = topics.map { |t| t[:id] }
      expect(ids).to include(topic_a.id, topic_b.id)
    end

    it 'returns the minimum submitted review count' do
      _topics, min = allocator.eligible_topics(reviewer)
      expect(min).to eq(0)
    end

    it 'excludes a topic the reviewer has already reviewed' do
      submit_review(reviewer_id: reviewer.id, reviewee_id: team_a.id)
      topics, _min = allocator.eligible_topics(reviewer)
      expect(topics.map { |t| t[:id] }).not_to include(topic_a.id)
    end

    it 'excludes topics above min_count + threshold' do
      assignment.update!(review_topic_threshold: 0)
      submit_review(reviewer_id: other_reviewer.id, reviewee_id: team_b.id)
      # topic_b now has 1 submitted review; min is 0 (topic_a), threshold is 0 → topic_b excluded
      topics, _min = allocator.eligible_topics(reviewer)
      expect(topics.map { |t| t[:id] }).not_to include(topic_b.id)
    end

    it 'includes each topic with its submitted review count' do
      submit_review(reviewer_id: other_reviewer.id, reviewee_id: team_a.id)
      topics, _min = allocator.eligible_topics(reviewer)
      topic_a_entry = topics.find { |t| t[:id] == topic_a.id }
      expect(topic_a_entry[:review_count]).to eq(1)
    end
  end
end
