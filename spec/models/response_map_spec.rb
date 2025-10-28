# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  # We’ll stub associations and queries heavily to isolate the method logic.

  let(:map) do
    described_class.new.tap do |m|
      # map.id is used via map_id
      allow(m).to receive(:id).and_return(123)
      allow(m).to receive(:map_id).and_return(123)
    end
  end

  let(:reviewee) { instance_double('Participant') }

  before do
    allow(map).to receive(:reviewee).and_return(reviewee)
  end

  def stub_last_response(submitted_at: nil, created_at: nil, round: nil)
    last_resp = instance_double('Response',
                                submitted_at: submitted_at,
                                created_at: created_at)
    allow(last_resp).to receive(:respond_to?).with(:round).and_return(true)
    allow(last_resp).to receive(:round).and_return(round)
    allow(Response).to receive(:where).with(map_id: map.map_id).and_return(
      double('AR::Relation', order: [last_resp])
    )
    last_resp
  end

  describe '#needs_update_link?' do
    context 'when there are no responses yet' do
      it 'returns true (should show Update)' do
        # map.response.empty? is called in your method; association name is singular in your app.
        # stub it to simulate empty association.
        allow(map).to receive(:response).and_return([])
        expect(map.needs_update_link?).to eq(true)
      end
    end

    context 'when there is a last response and reviewee has a newer submission time' do
      it 'returns true (newer artifact → Update)' do
        allow(map).to receive(:response).and_return([:anything]) # non-empty
        last_submitted_at = Time.utc(2025, 1, 10, 10, 0, 0)
        last = stub_last_response(submitted_at: last_submitted_at, created_at: last_submitted_at)

        allow(reviewee).to receive(:respond_to?).with(:latest_submission_at).and_return(true)
        allow(reviewee).to receive(:latest_submission_at).and_return(last_submitted_at + 3600) # 1h newer

        # This branch uses submitted_at comparison
        expect(map.needs_update_link?).to eq(true)
      end
    end

    context 'when there is a last response and reviewee submission is not newer' do
      it 'falls through to other checks (e.g., rounds) or returns false (Edit)' do
        allow(map).to receive(:response).and_return([:anything])
        last_submitted_at = Time.utc(2025, 1, 10, 10, 0, 0)
        stub_last_response(submitted_at: last_submitted_at, created_at: last_submitted_at)

        allow(reviewee).to receive(:respond_to?).with(:latest_submission_at).and_return(true)
        allow(reviewee).to receive(:latest_submission_at).and_return(last_submitted_at) # same time

        # if no round change, result should be false
        allow(map).to receive(:respond_to?).with(:current_round).and_return(false)

        expect(map.needs_update_link?).to eq(false)
      end
    end

    context 'when current_round is greater than last response round' do
      it 'returns true (new round → Update)' do
        allow(map).to receive(:response).and_return([:anything])
        # last response at round 1
        stub_last_response(submitted_at: Time.utc(2025, 1, 10, 10), created_at: Time.utc(2025, 1, 10, 10), round: 1)

        allow(map).to receive(:respond_to?).with(:current_round).and_return(true)
        allow(map).to receive(:current_round).and_return(2)

        # make sure reviewee submission branch doesn’t short-circuit
        allow(reviewee).to receive(:respond_to?).with(:latest_submission_at).and_return(false)

        expect(map.needs_update_link?).to eq(true)
      end
    end

    context 'when submitted_at is nil (falls back to created_at)' do
      it 'compares reviewee.latest_submission_at against created_at' do
        allow(map).to receive(:response).and_return([:anything])
        created = Time.utc(2025, 1, 10, 10)
        stub_last_response(submitted_at: nil, created_at: created)

        allow(reviewee).to receive(:respond_to?).with(:latest_submission_at).and_return(true)
        allow(reviewee).to receive(:latest_submission_at).and_return(created + 60) # newer by 1 minute

        # In your current method, you compare only when last.submitted_at exists.
        # If you later enhance the method to use (submitted_at || created_at),
        # this test will validate that behavior. For now, it should fall through:
        #   - If your code only checks submitted_at, it won't enter time-branch and may return false
        #   - If you enhance to coalesce, it should return true here.
        #
        # Adjust the expectation based on your final implementation.
        #
        # If you keep the current code (submitted_at only), expectation is false:
        # expect(map.needs_update_link?).to eq(false)
        #
        # If you enhance to use (submitted_at || created_at):
        # expect(map.needs_update_link?).to eq(true)

        # Recommendation: enhance method to coalesce submitted_at || created_at.
        # For now, set expectation to false to match your current code:
        expect(map.needs_update_link?).to eq(false)
      end
    end

    context 'when neither new submission nor new round' do
      it 'returns false (should show Edit)' do
        allow(map).to receive(:response).and_return([:anything])
        last_time = Time.utc(2025, 1, 10, 10)
        stub_last_response(submitted_at: last_time, created_at: last_time, round: 2)

        allow(reviewee).to receive(:respond_to?).with(:latest_submission_at).and_return(true)
        allow(reviewee).to receive(:latest_submission_at).and_return(last_time) # same

        allow(map).to receive(:respond_to?).with(:current_round).and_return(true)
        allow(map).to receive(:current_round).and_return(2) # same round

        expect(map.needs_update_link?).to eq(false)
      end
    end
  end
end
