# spec/models/response_map_spec.rb
require 'rails_helper'
require 'securerandom'

RSpec.describe ResponseMap, type: :model do
  describe '#needs_update_link?' do
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
        handle: reviewee_user.name,
        team: team
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
      expect(response_map.needs_update_link?).to be true
    end

    it 'returns false when the last submitted response is the most recent activity' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)

      expect(response_map.needs_update_link?).to be false
    end

    it 'returns true when the reviewee participant updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      reviewee_participant.update_column(:updated_at, response_time + 2.days)

      expect(response_map.needs_update_link?).to be true
    end

    it 'returns true when the reviewee team updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      team.update_column(:updated_at, response_time + 2.days)

      expect(response_map.needs_update_link?).to be true
    end

    it 'returns true when teams_participants updates after the last submitted response' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time)
      teams_participant_record.update_column(:updated_at, response_time + 2.days)

      expect(response_map.needs_update_link?).to be true
    end

    it 'ignores newer drafts when deciding update vs edit' do
      Response.create!(map_id: response_map.id, is_submitted: true, created_at: response_time, updated_at: response_time, round: 1)
      Response.create!(map_id: response_map.id, is_submitted: false, created_at: response_time + 2.days, updated_at: response_time + 2.days, round: 1)

      expect(response_map.needs_update_link?).to be false
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

      expect(response_map.needs_update_link?).to be true
    end
  end
end
