require 'rails_helper'

RSpec.describe FeedbackEmailService, type: :service do
  describe '#call' do
    let(:assignment)   { double('Assignment', name: 'Cool Project') }
    let(:feedback_map) { double('FeedbackResponseMap', reviewed_object_id: response_id) }
    let(:response_id)  { 77 }
    let(:response)     { double('Response', id: response_id, map_id: map_id) }
    let(:map_id)       { 99 }
    let(:response_map) { double('ResponseMap', reviewer_id: participant_id) }
    let(:participant_id){ 123 }
    let(:participant)  { double('AssignmentParticipant', user_id: user_id) }
    let(:user_id)      { 456 }
    let(:user)         { double('User', email: 'rev@example.com', fullname: 'Reviewer') }

    before do
      # Stub all the ActiveRecord lookups
      allow(Response).to             receive(:find).with(response_id).and_return(response)
      allow(ResponseMap).to          receive(:find).with(map_id).and_return(response_map)
      allow(AssignmentParticipant).to receive(:find).with(participant_id).and_return(participant)
      allow(User).to                 receive(:find).with(user_id).and_return(user)

      # Create a dummy Mailer class that implements .sync_message
      mailer_klass = Class.new do
        def self.sync_message(_defn)
          double(deliver: true)
        end
      end
      stub_const('Mailer', mailer_klass)
    end

    it 'builds the correct definition and tells the mailer to deliver it' do
      service = described_class.new(feedback_map, assignment)

      expect(Mailer).to receive(:sync_message) do |defn|
        expect(defn[:to]).to eq 'rev@example.com'
        expect(defn[:body][:type]).to eq 'Author Feedback'
        expect(defn[:body][:first_name]).to eq 'Reviewer'
        expect(defn[:body][:obj_name]).to eq 'Cool Project'
      end.and_return(double(deliver: true))

      service.call
    end
  end
end
