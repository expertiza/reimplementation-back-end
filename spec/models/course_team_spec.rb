# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseTeam, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor) do
    User.create!(
      name: 'instructor',
      full_name: 'Instructor User',
      email: 'instructor@example.com',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      institution_id: institution.id
    )
  end
  let(:course) { Course.create!(name: 'Course 1', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/course1') }
  let(:course_team) { CourseTeam.create!(parent_id: course.id, name: 'team 2') }

  def make_user(suffix)
    User.create!(
      name: suffix,
      email: "#{suffix}@example.com",
      full_name: suffix.split('_').map(&:capitalize).join(' '),
      password_digest: 'password',
      role_id: @roles[:student].id,
      institution_id: institution.id
    )
  end

  def make_participant(suffix)
    user = make_user(suffix)
    CourseParticipant.create!(user: user, parent_id: course.id, handle: user.name)
  end

  # -----------------------------------------------------------------------
  # Validations
  # -----------------------------------------------------------------------
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(course_team).to be_valid
    end

    it 'is not valid without a course' do
      team = build(:course_team, course: nil)
      expect(team).not_to be_valid
      expect(team.errors[:course]).to include('must exist')
    end

    it 'validates type must be CourseTeam' do
      team = build(:course_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course' or 'Mentor'")
    end
  end

  # -----------------------------------------------------------------------
  # Associations
  # -----------------------------------------------------------------------
  describe 'associations' do
    it { should belong_to(:course) }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:users).through(:teams_participants) }
  end

  # -----------------------------------------------------------------------
  # Membership — bullet point 1
  # -----------------------------------------------------------------------
  describe '#add_member' do
    context 'when participant is enrolled in the course' do
      it 'successfully adds the participant' do
        participant = make_participant('enrolled_student')

        result = course_team.add_member(participant)
        expect(result[:success]).to be true
        expect(course_team.has_member?(participant.user)).to be true
      end
    end

    context 'when user is NOT enrolled in the course' do
      it 'does not add the member' do
        unenrolled_user = make_user('unenrolled_student')

        result = course_team.add_member(unenrolled_user)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("#{unenrolled_user.name} is not a participant in this course")
      end

      it 'does not create a TeamsParticipant record' do
        unenrolled_user = make_user('unenrolled_student2')

        expect {
          course_team.add_member(unenrolled_user)
        }.not_to change(TeamsParticipant, :count)
      end
    end
  end
end