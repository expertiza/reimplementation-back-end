# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  
  include RolesHelper
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the full roles hierarchy once, to be shared by all examples.
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # ------------------------------------------------------------------------
  # Helper: DRY-up creation of student users with a predictable pattern.
  # ------------------------------------------------------------------------
  def create_student(suffix)
    User.create!(
      name:            suffix,
      email:           "#{suffix}@example.com",
      full_name:       suffix.split('_').map(&:capitalize).join(' '),
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # ------------------------------------------------------------------------
  # Shared Data Setup: Build core domain objects used across tests.
  # ------------------------------------------------------------------------
  let(:institution) do
    # All users belong to the same institution to satisfy foreign key constraints.
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    # The instructor will own assignments and courses in subsequent tests.
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:          @roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let(:team_owner) do
    User.create!(
      name:            "team_owner",
      full_name:       "Team Owner",
      email:           "team_owner@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }

  let(:assignment_team) do
    AssignmentTeam.create!(
      parent_id: assignment.id,
      name:      'team 1'
    )
  end

  before do
    # Create participant for team_owner and add them to the team
    @owner_participant = create(:assignment_participant, user: team_owner, assignment: assignment)
    assignment_team.add_member(@owner_participant)
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(assignment_team).to be_valid
    end

    it 'is not valid without an assignment' do
      team = build(:assignment_team, assignment: nil)
      expect(team).not_to be_valid
      expect(team.errors[:assignment]).to include("must exist")
    end

    it 'validates type must be AssignmentTeam' do
      team = build(:assignment_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'AssignmentTeam', 'CourseTeam', or 'MentoredTeam'")
    end
  end

  describe 'polymorphic methods' do
    it 'returns assignment as parent_entity' do
      expect(assignment_team.parent_entity).to eq(assignment)
    end

    it 'returns AssignmentParticipant as participant_class' do
      expect(assignment_team.participant_class).to eq(AssignmentParticipant)
    end

    it 'returns assignment as context_label' do
      expect(assignment_team.context_label).to eq('assignment')
    end

    it 'returns assignment max_team_size' do
      expect(assignment_team.max_team_size).to eq(3)
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the assignment' do
      it 'does not add the member to the team' do
        unenrolled_user = create_student("add_user")
        # Create participant for wrong assignment or none at all
        # In this case, we're not creating a participant, so the check should fail
        
        # Try to add user without proper participant
        unenrolled_participant = AssignmentParticipant.new(user: unenrolled_user)

        expect {
          assignment_team.add_member(unenrolled_participant)
        }.not_to change(TeamsParticipant, :count)
      end

      it 'returns error hash when participant not registered' do
        unenrolled_user = create_student("add_user_2")
        # Create participant but for different assignment
        other_assignment = Assignment.create!(name: "Other Assignment", instructor_id: instructor.id, max_team_size: 3)
        other_participant = AssignmentParticipant.create!(
          parent_id: other_assignment.id,
          user: unenrolled_user,
          handle: unenrolled_user.name
        )
        
        result = assignment_team.add_member(other_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant in this assignment/)
      end
    end

    context 'when user is properly enrolled' do
      it 'adds the member successfully' do
        enrolled_user = create_student("enrolled_user")
        participant = AssignmentParticipant.create!(
          parent_id: assignment.id,
          user: enrolled_user,
          handle: enrolled_user.name
        )

        expect {
          result = assignment_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change(TeamsParticipant, :count).by(1)
      end

      it 'returns success hash' do
        enrolled_user = create_student("enrolled_user_2")
        participant = AssignmentParticipant.create!(
          parent_id: assignment.id,
          user: enrolled_user,
          handle: enrolled_user.name
        )

        result = assignment_team.add_member(participant)
        expect(result[:success]).to be true
        expect(result[:error]).to be_nil
      end
    end

    context 'when team is full' do
      it 'rejects new members' do
        # Team already has 1 member (team_owner), add 2 more to reach max_team_size of 3
        2.times do |i|
          user = create_student("filler_#{i}")
          participant = AssignmentParticipant.create!(
            parent_id: assignment.id,
            user: user,
            handle: user.name
          )
          assignment_team.add_member(participant)
        end

        # Try to add one more
        overflow_user = create_student("overflow")
        overflow_participant = AssignmentParticipant.create!(
          parent_id: assignment.id,
          user: overflow_user,
          handle: overflow_user.name
        )

        result = assignment_team.add_member(overflow_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/full capacity/)
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:assignment) }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:users).through(:teams_participants) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }
    let(:unenrolled_user) { create(:user) }

    before do
      @participant = create(:assignment_participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user via participant' do
      result = assignment_team.add_member(@participant)
      expect(result[:success]).to be true
      expect(assignment_team.has_member?(enrolled_user)).to be true
    end

    it 'cannot add unenrolled user' do
      # Create participant for different assignment
      other_assignment = Assignment.create!(name: "Different Assignment", instructor_id: instructor.id, max_team_size: 3)
      wrong_participant = create(:assignment_participant, user: unenrolled_user, assignment: other_assignment)

      result = assignment_team.add_member(wrong_participant)

      expect(result[:success]).to be false
      expect(result[:error]).to match(/not a participant in this assignment/)
    end
  end

  describe '#copy_to_course_team' do
    it 'creates a new CourseTeam with copied members' do
      # Add another member to the team
      member = create(:user)
      participant = create(:assignment_participant, user: member, assignment: assignment)
      assignment_team.add_member(participant)

      # Copy to course team
      course_team = assignment_team.copy_to_course_team(course)

      expect(course_team).to be_a(CourseTeam)
      expect(course_team.name).to include('Course')
      expect(course_team.parent_id).to eq(course.id)
      # Members should be copied (note: copying creates CourseParticipants)
      expect(course_team.participants.count).to eq(assignment_team.participants.count)
    end
  end

  describe '#copy_to_assignment_team' do
    it 'creates a new AssignmentTeam with copied members' do
      other_assignment = Assignment.create!(name: "Assignment 2", instructor_id: instructor.id, max_team_size: 3)
      
      # Copy to new assignment team
      new_team = assignment_team.copy_to_assignment_team(other_assignment)

      expect(new_team).to be_a(AssignmentTeam)
      expect(new_team.name).to include('Copy')
      expect(new_team.parent_id).to eq(other_assignment.id)
      expect(new_team.participants.count).to eq(assignment_team.participants.count)
    end
  end
end
