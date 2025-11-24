require 'rails_helper'

RSpec.describe InvitationValidator do
  let(:assignment) { create(:assignment) }
  let(:from_participant) { create(:assignment_participant, assignment: assignment) }
  let(:to_participant) { create(:assignment_participant, assignment: assignment) }

  let(:valid_attributes) do
    {
      from_participant: from_participant,
      to_id: to_participant.id,
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
        expect(subject.errors[:base]).to include("must be one of A, D, W, R")
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
        subject.to_id = from_participant.id
        subject.validate
        expect(subject.errors[:base]).to include("to and from participants should be different")
      end
    end
  end
end
