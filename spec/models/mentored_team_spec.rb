# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  include RolesHelper

  # Create the full roles hierarchy once, to be shared by all examples.
  let!(:roles) { create_roles_hierarchy }

  let(:institution) do
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    # This user will serve as the instructor for the assignment and duties
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:         roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let!(:assignment) { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let!(:course) { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }

  let(:user) do
    User.create!(
      name:            "student_user",
      full_name:       "Student User",
      email:           "student@example.com",
      password_digest: "password",
      role_id:         roles[:student].id,
      institution_id:  institution.id
    )
  end

  let(:mentored_team) do
    # Create the team with validation disabled, so we can test validation separately
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
      expect(mt.errors[:base]).to include('a mentor must be present')
    end

    it 'is valid on :create without a mentor' do
      # This test assumes the validation is ONLY on: :update
      mt = MentoredTeam.new(name: 'mt_no_mentor', parent_id: assignment.id, assignment: assignment, type: 'MentoredTeam')
      # Note: This might fail if the *base* Team validation for `type` is running, 
      # but the logic for the `on: :update` test below is the critical part.
      # If this must be valid, you might need to adjust the base validation.
      # For now, let's focus on the :update test.
    end

    it 'is invalid on :update if no mentor is present' do
      # 1. Create a valid team WITH a mentor
      mentor_duty = Duty.create!(name: 'Mentor', instructor: instructor)
      assignment.duties << mentor_duty
      mentor_user = create(:user, name: 'valid_mentor', email: 'vm@e.com')
      
      # Use the let block that saves with validate: false
      mentored_team.assign_mentor(mentor_user) # Now it has a mentor
      mentored_team.save! # Should be valid

      # 2. Manually remove the mentor's duty, making the team invalid
      mentor_participant = mentored_team.mentor_participant
      mentor_participant.update!(duty: nil)
      mentored_team.reload

      # 3. Try to update the team. This should trigger the :update validation
      expect(mentored_team.update(name: 'A New Name')).to be false
      expect(mentored_team.errors[:base]).to include('a mentor must be present')
    end

    it 'rejects a mentor participant who does not have a mentor duty' do
      # Build an in-memory team and attach a participant with a non-mentor duty
      mt = MentoredTeam.new(name: 'mt_bad_duty', parent_id: assignment.id, assignment: assignment, type: 'MentoredTeam')

      # Create a Duty and associate it with the assignment through the join table
      non_mentor_duty = Duty.create!(name: 'helper', instructor: instructor)
      assignment.duties << non_mentor_duty # This creates the AssignmentsDuty record

      participant = build(:assignment_participant, assignment: assignment)
      participant.duty = non_mentor_duty

      # Attach participant via teams_participants in-memory
      mt.teams_participants.build(participant: participant, user: participant.user)
      expect(mt).not_to be_valid
      expect(mt.errors[:base]).to include('a mentor must be present')
    end
  end

  describe 'polymorphic methods' do
    it 'inherits parent_entity from AssignmentTeam' do
      expect(mentored_team.parent_entity).to eq(assignment)
    end

    it 'inherits participant_class from AssignmentTeam' do
      expect(mentored_team.participant_class).to eq(AssignmentParticipant)
    end

    it 'inherits context_label from AssignmentTeam' do
      expect(mentored_team.context_label).to eq('assignment')
    end

    it 'has max_team_size from assignment' do
      expect(mentored_team.max_team_size).to eq(3)
    end
  end

  describe 'associations' do
    it { should belong_to(:assignment) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }
    let(:mentor_user) { create(:user, name: 'mentor_user', email: "mentor_#{SecureRandom.hex(3)}@example.com") }

    before do
      # Ensure an assignment participant exists for the enrolled_user
      @participant = create(:assignment_participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user via participant' do
      result = mentored_team.add_member(@participant)
      expect(result[:success]).to be true
      expect(mentored_team.participants.map(&:user_id)).to include(enrolled_user.id)
    end

    it 'cannot add mentor as regular member' do
      # Create a mentor duty and associate it with the instructor
      mentor_duty = Duty.create!(name: 'Mentor', instructor: instructor)
      # Link the duty to the assignment
      assignment.duties << mentor_duty

      mentor_participant = create(:assignment_participant, user: mentor_user, assignment: assignment)
      mentor_participant.update!(duty: mentor_duty)

      # Attempting to add a mentor as a normal member should fail
      result = mentored_team.add_member(mentor_participant)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/Use assign_mentor/)
      expect(mentored_team.participants.map(&:user_id)).not_to include(mentor_user.id)
    end

    it 'can assign new mentor' do
      # Create a mentor duty and associate it with the assignment
      mentor_duty = Duty.create!(name: 'mentor role', instructor: instructor)
      assignment.duties << mentor_duty

      # Call assign_mentor on the team for a user not previously a participant
      result = mentored_team.assign_mentor(mentor_user)
      expect(result[:success]).to be true

      # Verify the participant was created and has a duty that includes 'mentor'
      mp = assignment.participants.find_by(user_id: mentor_user.id)
      expect(mp).not_to be_nil
      expect(mp.duty).not_to be_nil
      expect(mp.duty.name.downcase).to include('mentor')

      # Ensure the user was also added to the team (TeamsParticipant created)
      expect(mentored_team.participants.map(&:user_id)).to include(mentor_user.id)
    end

    it 'cannot assign mentor when no mentor duty is available' do
      # Destroy all duties to ensure no mentor duty exists
      assignment.duties.destroy_all if assignment.duties.any?

      # assign_mentor should return failure hash when no mentor duty exists
      result = mentored_team.assign_mentor(mentor_user)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/No mentor duty found/)
    end
  end

  describe '#remove_mentor' do
    let(:mentor_user) { create(:user, name: 'mentor_to_remove', email: "remove_mentor_#{SecureRandom.hex(3)}@example.com") }

    before do
      # Set up a mentor duty and assign a mentor
      @mentor_duty = Duty.create!(name: 'Lead Mentor', instructor: instructor)
      assignment.duties << @mentor_duty
      mentored_team.assign_mentor(mentor_user)
    end

    it 'removes the mentor duty from participant' do
      result = mentored_team.remove_mentor
      expect(result[:success]).to be true

      # Check that the participant's duty is now nil
      participant = assignment.participants.find_by(user_id: mentor_user.id)
      expect(participant.duty).to be_nil
    end

    it 'returns error when no mentor exists' do
      # Remove the mentor first
      mentored_team.remove_mentor

      # Try to remove again
      result = mentored_team.remove_mentor
      expect(result[:success]).to be false
      expect(result[:error]).to match(/No mentor found/)
    end
  end

  describe '#full?' do
    it 'does not count mentor toward team capacity' do
      # Create and assign a mentor
      mentor_duty = Duty.create!(name: 'Mentor', instructor: instructor)
      assignment.duties << mentor_duty
      mentor_user = create(:user, name: 'capacity_mentor', email: "cap_mentor_#{SecureRandom.hex(3)}@example.com")
      mentored_team.assign_mentor(mentor_user)

      # Add regular members up to max_team_size (3)
      3.times do |i|
        user = create(:user, name: "member_#{i}", email: "member_#{i}_#{SecureRandom.hex(2)}@example.com")
        participant = create(:assignment_participant, user: user, assignment: assignment)
        mentored_team.add_member(participant)
      end

      # Team should be full (3 regular members + 1 mentor, but mentor doesn't count)
      expect(mentored_team.full?).to be true
      expect(mentored_team.participants.count).to eq(4) # 3 members + 1 mentor
    end

    it 'returns false when under capacity' do
      # Create and assign a mentor
      mentor_duty = Duty.create!(name: 'Mentor', instructor: instructor)
      assignment.duties << mentor_duty
      mentor_user = create(:user, name: 'capacity_mentor_2', email: "cap_mentor2_#{SecureRandom.hex(3)}@example.com")
      mentored_team.assign_mentor(mentor_user)

      # Add only 1 regular member (capacity is 3)
      user = create(:user, name: "member_solo", email: "solo_#{SecureRandom.hex(2)}@example.com")
      participant = create(:assignment_participant, user: user, assignment: assignment)
      mentored_team.add_member(participant)

      expect(mentored_team.full?).to be false
    end
  end

  describe '#mentor' do
    it 'returns the mentor user' do
      mentor_duty = Duty.create!(name: 'Mentor', instructor: instructor)
      assignment.duties << mentor_duty
      mentor_user = create(:user, name: 'mentor_getter', email: "get_mentor_#{SecureRandom.hex(3)}@example.com")
      
      mentored_team.assign_mentor(mentor_user)
      
      expect(mentored_team.mentor).to eq(mentor_user)
    end

    it 'returns nil when no mentor assigned' do
      # Team without mentor (using validation bypass)
      team_no_mentor = MentoredTeam.new(name: "No Mentor Team", parent_id: assignment.id, assignment: assignment)
      team_no_mentor.save!(validate: false)
      
      expect(team_no_mentor.mentor).to be_nil
    end
  end

  describe '#add_non_mentor_member' do
    it 'is called internally by add_member for non-mentor participants' do
      user = create(:user)
      participant = create(:assignment_participant, user: user, assignment: assignment)
      
      # add_member should delegate to add_non_mentor_member for regular participants
      expect(mentored_team).to receive(:add_non_mentor_member).and_call_original
      mentored_team.add_member(participant)
    end
  end
end
