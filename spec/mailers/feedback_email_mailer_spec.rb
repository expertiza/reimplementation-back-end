# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbackEmailMailer, type: :mailer do
  # Mailer is initialized with a FeedbackResponseMap and an Assignment.
  # #call → ResponseMap.find(feedback_map.reviewed_object_id)
  #        → AssignmentParticipant.find(original_map.reviewer_id)
  #        → User.find(participant.user_id)
  #        → Mailer.sync_message(payload).deliver

  let(:reviewed_object_id) { 77 }
  let(:reviewer_id)        { 123 }
  let(:user_id)            { 456 }

  let(:feedback_map)   { double('FeedbackResponseMap', reviewed_object_id: reviewed_object_id) }
  let(:assignment)     { double('Assignment', name: 'Cool Project') }
  let(:original_map)   { double('ResponseMap', reviewer_id: reviewer_id) }
  let(:participant)    { double('AssignmentParticipant', user_id: user_id) }
  let(:user)           { double('User', email: 'rev@example.com', name: 'Reviewer Name') }
  let(:mail_message) { double('MailMessage', deliver: true) }

  subject(:service) { described_class.new(feedback_map, assignment) }

  before do
    allow(ResponseMap).to receive(:find).with(reviewed_object_id).and_return(original_map)
    allow(AssignmentParticipant).to receive(:find).with(reviewer_id).and_return(participant)
    allow(User).to receive(:find).with(user_id).and_return(user)
    allow(ActionMailer::Parameterized::Mailer).to receive(:sync_message).and_return(mail_message)
  end

  describe '#call' do
    it 'looks up the original ResponseMap by reviewed_object_id' do
      expect(ResponseMap).to receive(:find).with(reviewed_object_id)
      service.call
    end

    it 'looks up the AssignmentParticipant by reviewer_id' do
      expect(AssignmentParticipant).to receive(:find).with(reviewer_id)
      service.call
    end

    it 'looks up the User by user_id' do
      expect(User).to receive(:find).with(user_id)
      service.call
    end

    it 'sends to the reviewer email address' do
      expect(ActionMailer::Parameterized::Mailer).to receive(:sync_message) do |defn|
        expect(defn[:to]).to eq('rev@example.com')
      end.and_return(mail_message)
      service.call
    end

    it 'sets body type to "Author Feedback"' do
      expect(ActionMailer::Parameterized::Mailer).to receive(:sync_message) do |defn|
        expect(defn[:body][:type]).to eq('Author Feedback')
      end.and_return(mail_message)
      service.call
    end

    it 'sets body name to the user name' do
      expect(ActionMailer::Parameterized::Mailer).to receive(:sync_message) do |defn|
        expect(defn[:body][:name]).to eq('Reviewer Name')
      end.and_return(mail_message)
      service.call
    end

    it 'sets body obj_name to the assignment name' do
      expect(ActionMailer::Parameterized::Mailer).to receive(:sync_message) do |defn|
        expect(defn[:body][:obj_name]).to eq('Cool Project')
      end.and_return(mail_message)
      service.call
    end

    it 'calls deliver on the mail message' do
      expect(mail_message).to receive(:deliver)
      service.call
    end

    context 'when the original ResponseMap is not found' do
      before { allow(ResponseMap).to receive(:find).with(reviewed_object_id).and_raise(ActiveRecord::RecordNotFound) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the AssignmentParticipant is not found' do
      before { allow(AssignmentParticipant).to receive(:find).with(reviewer_id).and_raise(ActiveRecord::RecordNotFound) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the User is not found' do
      before { allow(User).to receive(:find).with(user_id).and_raise(ActiveRecord::RecordNotFound) }

      it 'raises ActiveRecord::RecordNotFound' do
        expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
