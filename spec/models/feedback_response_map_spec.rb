# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbackResponseMap, type: :model do
  subject(:frm) { FeedbackResponseMap.new }

  # ─── #title ─────────────────────────────────────────────────────────────────

  describe '#title' do
    it 'returns "Feedback"' do
      expect(frm.title).to eq('Feedback')
    end
  end

  # ─── #get_title ──────────────────────────────────────────────────────────────

  describe '#get_title' do
    it 'returns the FEEDBACK_RESPONSE_MAP_TITLE constant value' do
      expect(frm.get_title).to eq(ResponseMapSubclassTitles::FEEDBACK_RESPONSE_MAP_TITLE)
    end

    it 'equals "Feedback"' do
      expect(frm.get_title).to eq('Feedback')
    end
  end

  # ─── #questionnaire_type ─────────────────────────────────────────────────────

  describe '#questionnaire_type' do
    it 'returns "AuthorFeedback"' do
      expect(frm.questionnaire_type).to eq('AuthorFeedback')
    end
  end

  # ─── #survey? ────────────────────────────────────────────────────────────────

  describe '#survey?' do
    it 'returns false' do
      expect(frm.survey?).to be false
    end
  end

  # ─── #assignment ─────────────────────────────────────────────────────────────

  describe '#assignment' do
    it 'returns the assignment via review.map.assignment' do
      assignment = instance_double('Assignment')
      map        = instance_double('ResponseMap')
      review     = instance_double('Response')
      allow(frm).to receive(:review).and_return(review)
      allow(review).to receive(:map).and_return(map)
      allow(map).to receive(:assignment).and_return(assignment)
      expect(frm.assignment).to eq(assignment)
    end
  end

  # ─── #questionnaire ──────────────────────────────────────────────────────────

  describe '#questionnaire' do
    it 'returns the questionnaire matching reviewed_object_id' do
      questionnaire = instance_double('Questionnaire')
      frm_with_id   = FeedbackResponseMap.new(reviewed_object_id: 1)
      allow(Questionnaire).to receive(:find_by).with(id: 1).and_return(questionnaire)
      expect(frm_with_id.questionnaire).to eq(questionnaire)
    end

    it 'returns nil when no questionnaire matches reviewed_object_id' do
      frm_with_id = FeedbackResponseMap.new(reviewed_object_id: 99_999)
      allow(Questionnaire).to receive(:find_by).with(id: 99_999).and_return(nil)
      expect(frm_with_id.questionnaire).to be_nil
    end
  end

  # ─── #contributor ────────────────────────────────────────────────────────────

  describe '#contributor' do
    it 'returns the reviewee' do
      reviewee = instance_double('Participant')
      allow(frm).to receive(:reviewee).and_return(reviewee)
      expect(frm.contributor).to eq(reviewee)
    end
  end

  # ─── #send_notification_email ────────────────────────────────────────────────

  describe '#send_notification_email' do
    let(:assignment) { instance_double('Assignment') }
    let(:mailer)     { instance_double(FeedbackEmailMailer) }

    context 'when assignment is present' do
      before do
        allow(frm).to receive(:assignment).and_return(assignment)
        allow(assignment).to receive(:present?).and_return(true)
        allow(FeedbackEmailMailer).to receive(:new).with(frm, assignment).and_return(mailer)
        allow(mailer).to receive(:call)
      end

      it 'initialises FeedbackEmailMailer with self and the assignment' do
        expect(FeedbackEmailMailer).to receive(:new).with(frm, assignment).and_return(mailer)
        frm.send_notification_email
      end

      it 'calls the mailer' do
        expect(mailer).to receive(:call)
        frm.send_notification_email
      end
    end

    context 'when assignment is not present' do
      before { allow(frm).to receive(:assignment).and_return(nil) }

      it 'does not instantiate the mailer' do
        expect(FeedbackEmailMailer).not_to receive(:new)
        frm.send_notification_email
      end

      it 'returns without raising' do
        expect { frm.send_notification_email }.not_to raise_error
      end
    end

    context 'when the mailer raises a StandardError' do
      before do
        allow(frm).to receive(:assignment).and_return(assignment)
        allow(assignment).to receive(:present?).and_return(true)
        allow(FeedbackEmailMailer).to receive(:new).and_return(mailer)
        allow(mailer).to receive(:call).and_raise(StandardError, 'smtp failure')
      end

      it 'does not propagate the error' do
        expect { frm.send_notification_email }.not_to raise_error
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/FeedbackEmail failed/)
        frm.send_notification_email
      end
    end
  end

  # ─── .build_from_params ──────────────────────────────────────────────────────

  describe '.build_from_params' do
    let(:params) { { reviewer_id: 1, reviewee_id: 2, reviewed_object_id: 3 } }

    it 'returns a FeedbackResponseMap instance' do
      expect(FeedbackResponseMap.build_from_params(params)).to be_a(FeedbackResponseMap)
    end

    it 'returns an unsaved record' do
      expect(FeedbackResponseMap.build_from_params(params)).to be_new_record
    end

    it 'assigns the provided attributes' do
      built = FeedbackResponseMap.build_from_params(params)
      expect(built.reviewer_id).to eq(1)
      expect(built.reviewee_id).to eq(2)
      expect(built.reviewed_object_id).to eq(3)
    end
  end
end
