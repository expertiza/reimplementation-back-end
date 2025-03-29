require 'rails_helper'

RSpec.describe Team, type: :model do

  let(:instructor_role) { Role.create!(name: "Instructor") }

  let(:student_role) { Role.create!(name: "Student") }

  let(:instructor) do
    User.create!(
      name: "test_instructor",
      password_digest: "password",
      role: instructor_role,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:student_user) do
    User.create!(
      name: "student_user",
      password_digest: "password",
      role: student_role,
      full_name: "Student User",
      email: "student@example.com"
    )
  end

  let(:assignment) { Assignment.create!(name: "Test Assignment", instructor: instructor) }
  let(:team) { Team.create!(assignment: assignment) }
  let(:participant) { Participant.create!(user: student_user, assignment: assignment) }


  describe '#full?' do
    it 'returns false when team has fewer participants than max allowed' do
      allow(team).to receive(:max_participants).and_return(3)
      allow(team.participants).to receive(:count).and_return(2)

      expect(team.full?).to be_falsey
    end

    it 'returns true when team has maximum participants allowed' do
      allow(team).to receive(:max_participants).and_return(3)
      allow(team.participants).to receive(:count).and_return(3)

      expect(team.full?).to be_truthy
    end
  end

  describe '#participant?' do
    it 'returns true if participant is part of the team' do
      allow(team.participants).to receive(:exists?).with(id: participant.id).and_return(true)

      expect(team.participant?(participant)).to be_truthy
    end

    it 'returns false if participant is not part of the team' do
      allow(team.participants).to receive(:exists?).with(id: participant.id).and_return(false)

      expect(team.participant?(participant)).to be_falsey
    end
  end

  describe '#add_member' do
    context 'when participant already exists on the team' do
      it 'raises an error' do
        team.participants << participant
        expect {
          team.add_member(participant)
        }.to raise_error(
               RuntimeError,
               "The participant #{participant.user.name} is already a member of this team"
             )
      end
    end
  end


  describe '#add_participants_with_validation' do
    context 'when adding participant succeeds' do
      it 'returns a success response' do
        allow(team).to receive(:add_member).with(participant).and_return(true)

        result = team.add_participants_with_validation(participant)

        expect(result).to eq({ success: true })
      end
    end

    context 'when adding participant fails because team is full' do
      it 'returns a failure response with a team-full error message' do
        allow(team).to receive(:add_member).with(participant).and_return(false)

        result = team.add_participants_with_validation(participant)

        expect(result).to eq({ success: false, error: "Unable to add participant: team is at full capacity." })
      end
    end

    context 'when adding participant raises an exception' do
      it 'returns a failure response with the exception message' do
        allow(team).to receive(:add_member).with(participant).and_raise(StandardError.new('Some error'))

        result = team.add_participants_with_validation(participant)

        expect(result).to eq({ success: false, error: 'Some error' })
      end
    end
  end
end
