require "rails_helper"
describe Participant do

  let(:team) { FactoryBot.build(:assignment_participant, id: 1, name: 'myTeam') }
  let(:user) { FactoryBot.build(:student, id: 4, name: 'no name', fullname: 'no two') }
  let(:teams_participant) { FactoryBot.build(:teams_participant, id: 1, user: user, team: team) }
  let(:topic) { FactoryBot.build(:topic) }
  let(:participant) { FactoryBot.build(:participant, id: 3, user: FactoryBot.build(:student, name: 'Jane', fullname: 'Doe, Jane', id: 1), handle: 'handle') }
  let(:participant2) { FactoryBot.build(:participant, id: 2, user: FactoryBot.build(:student, name: 'John', fullname: 'Doe, John', id: 2)) }
  let(:participant3) { FactoryBot.build(:participant, id: 1, can_review: false, user: FactoryBot.build(:student, name: 'King', fullname: 'Titan, King', id: 3)) }
  let(:participant4) { FactoryBot.build(:participant, id: 4) }
  let(:unsorted_participants) {[participant3, participant, participant2]}
  let(:sorted_participants_by_name) {[participant, participant2, participant3]}
  let(:sorted_participants_by_id) {[participant3, participant2, participant]}


  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  # Test to check the Participant#team method.
  # Must return the team_participant object using the "participant_id"
  describe '#team' do
    it 'returns the team of the participant' do
      allow(participant4).to receive(:user).and_return(user)
      allow(TeamsParticipant).to receive(:find_by).with(participant_id: 4).and_return(teams_participant)
      expect(teams_participant).to eq(teams_participant)
    end
  end


  # Test to check the Participant#name method.
  # Must return the first name as a string of the participant
  describe '#name' do
    it 'returns the name of the user' do
      expect(participant.name).to eq('Jane')
    end
  end

  # Test to check Participant#fullname
  # Must return the fullname of the participant as a string 
  describe '#fullname' do
    it 'returns the full name of the user' do
      expect(participant.fullname).to eq('Doe, Jane')
    end
  end

  # Test to check Participant#handle
  # Must return the current handle of the participant as a string
  describe '#handle' do
    it 'returns the handle of the participant' do
      expect(participant.handle(nil)).to eq("handle")
    end
  end

  # Test to check Participant#sort_participants
  # Must return the partipants in a sorted manner by name or id (in this order)
  describe '#sort_participants' do
    it 'returns a sorted list of participants alphabetically  by name' do
      expect(Participant.sort_participants(unsorted_participants,'name')).to eq(sorted_participants_by_name)
    end
    it 'returns a sorted list of participants numerically ' do
      unsorted = [participant3, participant, participant2]
      sorted = [participant, participant2, participant]
      expect(Participant.sort_participants(unsorted_participants,'id')).to eq(sorted_participants_by_id)
    end
  end

  # Test to check the topic name the participant is taking part in
  # Must retirn the top_name as a string
  describe '#topic_name' do
    it 'returns the participant topic name when nil' do
      expect(participant.topic_name).to eq('<center>&#8212;</center>')
    end
    it 'returns the participant topic name when not nil' do
      allow(participant).to receive(:topic).and_return(topic)
      expect(participant.topic_name).to eq('Hello world!')
    end
  end

  # Test to check the Participant#authorizations - current authorization/permissions that participant has
  # Must return if participant can_submit, can_review and can_take_quiz (as boolean values)
  describe '#authorization' do
    it 'returns participant when no arguments are passed' do
      allow(participant).to receive(:can_submit).and_return(nil)
      allow(participant).to receive(:can_review).and_return(nil)
      allow(participant).to receive(:can_take_quiz).and_return(nil)
      expect(participant.authorization).to eq('participant')
    end
    it 'returns reader when no arguments are passed' do
      allow(participant).to receive(:can_submit).and_return(false)
      allow(participant).to receive(:can_review).and_return(true)
      allow(participant).to receive(:can_take_quiz).and_return(true)
      expect(participant.authorization).to eq('reader')
    end
    it 'returns submitter when no arguments are passed' do
      allow(participant).to receive(:can_submit).and_return(true)
      allow(participant).to receive(:can_review).and_return(false)
      allow(participant).to receive(:can_take_quiz).and_return(false)
      expect(participant.authorization).to eq('submitter')
    end
    it 'returns reviewer when no arguments are passed' do
      allow(participant).to receive(:can_submit).and_return(false)
      allow(participant).to receive(:can_review).and_return(true)
      allow(participant).to receive(:can_take_quiz).and_return(false)
      expect(participant.authorization).to eq('reviewer')
    end
  end

  # Test to check Participant#export_fields - export the fields interested in when exporting the detials of the participant
  describe '#export_fields' do
    let(:options) { { 'personal_details' => 'true', 'role' => 'true', 'parent' => 'true', 'email_options' => 'true', 'handle' => 'true' } }
    it 'returns the participant data in the correct format' do
      expected_result = "name", "full name", "email", "role", "parent", "email on submission", "email on review", "email on metareview", "handle"
      expect(Participant.export_fields(options)).to eq(expected_result)
    end
  end
  # Test to check Participant#export
  it '#export' do
    csv = []
    parent_id = 1
    options = nil
    allow(Participant).to receive_message_chain(:where, :find_each).with(parent_id: 1).with(no_args).and_yield(participant)
    allow(participant).to receive(:user).and_return(FactoryBot.build(:student, name: 'student2065', fullname: '2065, student'))
    options = { 'personal_details' => 'true', 'role' => 'true' }
    expect(Participant.export([], 1, options)).to eq(
                                                    [['student2065',
                                                      '2065, student',
                                                      nil,
                                                      nil]]
                                                  )
  end

end
