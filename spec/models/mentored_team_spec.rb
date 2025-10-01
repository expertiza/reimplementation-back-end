# frozen_string_literal: true

# spec/models/mentored_team_spec.rb
require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  include RolesHelper

  # Create the full roles hierarchy once, to be shared by all examples.
  let!(:roles) { create_roles_hierarchy }

  let(:institution) do
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:         roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let!(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let!(:course)      { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }

  let(:user) do
    User.create!(
      name:            "student_user",
      full_name:       "Student User",
      email:           "student@example.com",
      password_digest: "password",
      role_id:          roles[:student].id,
      institution_id:  institution.id
    )
  end

  let(:mentored_team) do
    t = MentoredTeam.new(name: "MentoredTeam #{SecureRandom.hex(4)}", parent_id: assignment.id, assignment: assignment)
    t.save!(validate: false)
    t
  end

  describe 'validations' do
    it 'requires type to be MentoredTeam' do
      mt = MentoredTeam.new(name: 'mt', parent_id: assignment.id, assignment: assignment)
      expect(mt.type).to eq('MentoredTeam')
    end

    it 'requires a mentor participant (duty present) on the team' do
      # Build an unsaved MentoredTeam with no participants
      mt = MentoredTeam.new(name: 'mt_no_mentor', parent_id: assignment.id, assignment: assignment, type: 'MentoredTeam')
      expect(mt).not_to be_valid
      expect(mt.errors[:base]).to include('mentor must be present')
    end

    it 'rejects a mentor participant who does not have a mentor duty' do
      # Build an in-memory team and attach a participant with a non-mentor duty
      mt = MentoredTeam.new(name: 'mt_bad_duty', parent_id: assignment.id, assignment: assignment, type: 'MentoredTeam')

      # create a non-mentor duty and an assignment participant
      non_mentor_duty = Duty.new(name: 'helper', assignment: assignment, max_members_for_duty: 1)
      participant = build(:assignment_participant, assignment: assignment)
      participant.duty = non_mentor_duty

      # attach participant via teams_participants in-memory
      mt.teams_participants.build(participant: participant, user: participant.user)
      expect(mt).not_to be_valid
      expect(mt.errors[:base]).to include('mentor must be present')
    end
  end

  describe 'associations' do
    it { should belong_to(:assignment) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }
    let(:mentor_user)   { create(:user, name: 'mentor_user', email: "mentor_#{SecureRandom.hex(3)}@example.com") }

    before do
      # ensure assignment participant exists for enrolled_user
      @participant = create(:assignment_participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user' do
      # mentored_team persisted via let(:mentored_team) (validate:false)
      result = mentored_team.add_member(enrolled_user)
      # MentoredTeam#add_member returns boolean true/false; underlying Team#add_member returns {success: true}
      expect(result).to be_truthy
      expect(mentored_team.participants.map(&:user_id)).to include(enrolled_user.id)
    end

    it 'cannot add mentor as member' do
      # create a mentor duty and participant that is a mentor
      mentor_duty = Duty.create!(name: 'Mentor', assignment: assignment, max_members_for_duty: 1)
      mentor_participant = create(:assignment_participant, user: mentor_user, assignment: assignment)
      mentor_participant.update!(duty: mentor_duty)

      # attempting to add a mentor as a normal member should fail
      res = mentored_team.add_member(mentor_user)
      expect(res).to be_falsey
      expect(mentored_team.participants.map(&:user_id)).not_to include(mentor_user.id)
    end

    it 'can assign new mentor' do
      # add a mentor duty to assignment so find_mentor_duty can find it
      Duty.create!(name: 'mentor role', assignment: assignment, max_members_for_duty: 1)

      # call assign_mentor on mentored_team for a user not previously a participant
      res = mentored_team.assign_mentor(mentor_user)
      expect(res).to be true

      # verify the participant was created and has a duty that includes 'mentor'
      mp = assignment.participants.find_by(user_id: mentor_user.id)
      expect(mp).not_to be_nil
      expect(mp.duty).not_to be_nil
      expect(mp.duty.name.downcase).to include('mentor')

      # ensure the user was also added to the team (TeamsParticipant created)
      expect(mentored_team.participants.map(&:user_id)).to include(mentor_user.id)
    end

    it 'cannot assign non-mentor as mentor' do
      # Remove any mentor duty on assignment (ensure none exist)
      assignment.duties.destroy_all if assignment.duties.any?

      # assign_mentor should return false when no mentor duty exists
      res = mentored_team.assign_mentor(mentor_user)
      expect(res).to be false
    end
  end
end
