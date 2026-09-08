# spec/models/response_map_spec.rb
require 'rails_helper'
require 'securerandom'

RSpec.describe ResponseMap, type: :model do
  describe '#has_submission_been_updated?' do
    def create_role(label)
      Role.create!(name: "#{label} #{SecureRandom.hex(4)}")
    end

    def create_user(prefix, role, institution)
      User.create!(
        name: "#{prefix}_#{SecureRandom.hex(4)}",
        email: "#{prefix}_#{SecureRandom.hex(4)}@example.com",
        password: 'password',
        full_name: "#{prefix.capitalize} User",
        role: role,
        institution: institution
      )
    end

    let(:institution) { Institution.create!(name: "Institution #{SecureRandom.hex(4)}") }
    let(:student_role) { create_role('Student') }
    let(:instructor_role) { create_role('Instructor') }

    let(:instructor_user) { create_user('instructor', instructor_role, institution) }

    let(:assignment) do
      Assignment.create!(
        name: "Assignment #{SecureRandom.hex(4)}",
        directory_path: "dir_#{SecureRandom.hex(4)}",
        instructor: instructor_user
      )
    end

    let(:team) do
      AssignmentTeam.create!(
        name: "Team #{SecureRandom.hex(4)}",
        type: 'AssignmentTeam',
        parent_id: assignment.id
      )
    end

    let(:reviewer_user) { create_user('reviewer', student_role, institution) }
    let(:reviewee_user) { create_user('reviewee', student_role, institution) }

    let(:reviewer_participant) do
      AssignmentParticipant.create!(
        user: reviewer_user,
        assignment: assignment,
        parent_id: assignment.id,
        handle: reviewer_user.name
      )
    end

    let(:reviewee_participant) do
      AssignmentParticipant.create!(
        user: reviewee_user,
        assignment: assignment,
        parent_id: assignment.id,
        handle: reviewee_user.name
      )
    end

    let!(:teams_participant_record) do
      TeamsParticipant.create!(participant: reviewee_participant, team: team, user: reviewee_user)
    end

    let!(:response_map) do
      ResponseMap.create!(
        assignment: assignment,
        reviewer: reviewer_participant,
        reviewee: reviewee_participant
      )
    end

    let(:base_time) { Time.zone.now - 5.days }
    let(:response_time) { base_time + 1.day }

    before do
      reviewee_participant.update_column(:updated_at, base_time)
      team.update_column(:updated_at, base_time)
      teams_participant_record.update_column(:updated_at, base_time)
    end

    it 'returns true when no submitted response exists yet' do
      expect(response_map.has_submission_been_updated?).to be true
    end

    it 'returns false when the last submitted response is the most recent activity' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)

      expect(response_map.has_submission_been_updated?).to be false
    end

    it 'returns true when the reviewee participant updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      reviewee_participant.update_column(:updated_at, response_time + 2.days)

      expect(response_map.has_submission_been_updated?).to be true
    end

    it 'returns true when the reviewee team updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      team.update_column(:updated_at, response_time + 2.days)

      expect(response_map.has_submission_been_updated?).to be true
    end

    it 'returns true when teams_participants updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      teams_participant_record.update_column(:updated_at, response_time + 2.days)

      expect(response_map.has_submission_been_updated?).to be true
    end

    it 'ignores newer drafts when deciding update vs edit' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time, round: 1)
      Response.create!(map_id: response_map.id, is_submitted: false, created_at: response_time + 2.days, updated_at: response_time + 2.days, round: 1)

      expect(response_map.has_submission_been_updated?).to be false
    end

    it 'returns true when a later review round has passed since the last response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)

      assignment.due_dates.create!(
        due_at: response_time + 1.day,
        deadline_type_id: 1,
        submission_allowed_id: 1,
        review_allowed_id: 1,
        round: 1
      )

      assignment.due_dates.create!(
        due_at: Time.zone.now - 1.day,
        deadline_type_id: 1,
        submission_allowed_id: 1,
        review_allowed_id: 1,
        round: 2
      )

      expect(response_map.has_submission_been_updated?).to be true
    end
  end

  describe '.compute_average_reviewer_score' do
    def map_with_grade(grade)
      instance_double(ResponseMap, review_grade: grade)
    end

    it 'returns nil when passed nil' do
      expect(ResponseMap.compute_average_reviewer_score(nil)).to be_nil
    end

    it 'returns nil when passed an empty array' do
      expect(ResponseMap.compute_average_reviewer_score([])).to be_nil
    end

    it 'returns nil when all maps have a nil review_grade' do
      maps = [map_with_grade(nil), map_with_grade(nil)]
      expect(ResponseMap.compute_average_reviewer_score(maps)).to be_nil
    end

    it 'returns 100.0 when a single map has a perfect review_grade of 1.0' do
      expect(ResponseMap.compute_average_reviewer_score([map_with_grade(1.0)])).to eq(100.0)
    end

    it 'returns 0.0 when a single map has a review_grade of 0.0' do
      expect(ResponseMap.compute_average_reviewer_score([map_with_grade(0.0)])).to eq(0.0)
    end

    it 'averages two maps into the correct score' do
      # (0.5 + 0.75) / 2 * 100 = 62.5
      maps = [map_with_grade(0.5), map_with_grade(0.75)]
      expect(ResponseMap.compute_average_reviewer_score(maps)).to eq(62.5)
    end

    it 'excludes nil-grade maps from the average' do
      # Only 0.8 contributes → 0.8 / 1 * 100 = 80.0
      maps = [map_with_grade(nil), map_with_grade(0.8)]
      expect(ResponseMap.compute_average_reviewer_score(maps)).to eq(80.0)
    end

    it 'computes an unweighted average (all maps count equally regardless of score)' do
      # Three maps: 0.4, 0.6, 0.8 → avg 0.6 → 60.0
      maps = [map_with_grade(0.4), map_with_grade(0.6), map_with_grade(0.8)]
      expect(ResponseMap.compute_average_reviewer_score(maps)).to eq(60.0)
    end

    it 'rounds the result to two decimal places' do
      # (0.1 + 0.2 + 0.3) / 3 * 100 = 20.0 (exact in this case, but covers rounding path)
      maps = [map_with_grade(0.1), map_with_grade(0.2), map_with_grade(0.3)]
      expect(ResponseMap.compute_average_reviewer_score(maps)).to eq(20.0)
    end
  end
end
