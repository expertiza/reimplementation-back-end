require 'rails_helper'
require 'swagger_helper'

RSpec.describe InvitationValidator do
    before(:all) do
        @roles = create_roles_hierarchy
    end

    let(:instructor) { create(:user, role_id: @roles[:instructor].id, name: "profa", full_name: "Prof A", email: "profa@example.com")}
    let(:user1) do
        User.create!( name: "student", password_digest: "password",role_id: @roles[:student].id, full_name: "Student Name",email: "student@example.com") 
    end

    let(:user2) do
        User.create!( name: "student2", password_digest: "password", role_id: @roles[:student].id, full_name: "Student Two", email: "student2@example.com")
    end
    let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: instructor.id) }
    let(:team1) { AssignmentTeam.create!(name: "Team1", parent_id: assignment.id) }
    let(:team2) { AssignmentTeam.create!(name: "Team2", parent_id: assignment.id) }

    let(:participant1) { AssignmentParticipant.create!(user: user1, parent_id: assignment.id, handle: 'user1_handle') }
    let(:participant2) { AssignmentParticipant.create!(user: user2, parent_id: assignment.id, handle: 'user2_handle') }

  let(:valid_attributes) do
    {
      from_participant: participant1,
      to_id: participant2.id,
      assignment_id: assignment.id,
      reply_status: 'W'
    }
  end

  subject { Invitation.new(valid_attributes) }

  describe 'validations' do
    it 'is valid with correct attributes' do
      expect(subject).to be_valid
    end

    context 'invitee validation' do
      it 'adds error if invitee is not part of assignment' do
        subject.to_id = 0 # non-existent participant
        subject.validate
        expect(subject.errors[:base]).to include("the participant is not part of this assignment")
      end
    end

    context 'reply status validation' do
      it 'adds error if reply_status is missing' do
        subject.reply_status = nil
        subject.validate
        expect(subject.errors[:base]).to include("must be present and have a maximum length of 1")
      end

      it 'adds error if reply_status is too long' do
        subject.reply_status = 'AB'
        subject.validate
        expect(subject.errors[:base]).to include("must be present and have a maximum length of 1")
      end

      it 'adds error if reply_status is not included in allowed statuses' do
        subject.reply_status = 'X'
        subject.validate
        expect(subject.errors[:base]).to include("must be one of A, D, W, and R")
      end
    end

    context 'duplicate invitation validation' do
      before do
        Invitation.create!(valid_attributes)
      end

      it 'adds error if duplicate invitation exists' do
        duplicate_invitation = Invitation.new(valid_attributes)
        duplicate_invitation.validate
        expect(duplicate_invitation.errors[:base]).to include("You cannot have duplicate invitations")
      end
    end

    context 'to/from participant difference validation' do
      it 'adds error if to and from are same participant' do
        subject.to_id = participant1.id
        subject.validate
        expect(subject.errors[:base]).to include("to and from participants should be different")
      end
    end
  end
end