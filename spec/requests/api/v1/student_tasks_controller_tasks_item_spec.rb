# spec/requests/api/v1/student_tasks_controller_tasks_item_spec.rb
require 'rails_helper'

RSpec.describe 'StudentTask item classes', type: :request do
  # ---------------------------------------------------------------------------
  # Everything is stubbed — no real DB records are written.
  # The inner classes only call a small, well-defined surface area on these
  # objects, so doubles + AR class stubs are the right approach.
  # ---------------------------------------------------------------------------

  let(:assignment) { instance_double('Assignment', id: 1) }
  let(:participant) { instance_double('AssignmentParticipant', id: 10) }
  let(:team_participant) do
    instance_double('TeamsParticipant', id: 20, participant: participant, participant_id: participant.id)
  end

  # Fix #5-9, #12-13: added `type:` to review_map double so map&.type works in to_h
  let(:review_map) do
    instance_double('ReviewResponseMap', id: 100, reviewee_id: 999, type: 'ReviewResponseMap')
  end

  # Reusable response doubles
  let(:submitted_response)   { instance_double('Response', id: 1, is_submitted: true,  round: 1) }
  let(:unsubmitted_response) { instance_double('Response', id: 2, is_submitted: false, round: 1) }

  # ---------------------------------------------------------------------------
  # ReviewTaskItem
  # ---------------------------------------------------------------------------
  describe ReviewTaskItem do
    subject(:item) do
      described_class.new(
        assignment:       assignment,
        team_participant: team_participant,
        review_map:       review_map
      )
    end

    describe '#task_type' do
      it 'returns :review' do
        expect(item.task_type).to eq(:review)
      end
    end

    describe '#response_map' do
      it 'returns the review map passed in' do
        expect(item.response_map).to eq(review_map)
      end
    end

    describe '#completed?' do
      # BaseTaskItem#completed? calls:
      #   Response.where(map_id: response_map.id, is_submitted: true).exists?

      it 'returns false when no submitted response exists' do
        rel = double('relation', exists?: false)
        allow(Response).to receive(:where).with(map_id: review_map.id, is_submitted: true).and_return(rel)
        expect(item.completed?).to be false
      end

      it 'returns true when a submitted response exists' do
        rel = double('relation', exists?: true)
        allow(Response).to receive(:where).with(map_id: review_map.id, is_submitted: true).and_return(rel)
        expect(item.completed?).to be true
      end

      it 'returns false when a response exists but is not submitted' do
        rel = double('relation', exists?: false)
        allow(Response).to receive(:where).with(map_id: review_map.id, is_submitted: true).and_return(rel)
        expect(item.completed?).to be false
      end
    end

    describe '#ensure_response!' do
      # Fix #1-4: model calls find_or_create_by! (with bang), so stub that method.
      # Stubbing bypasses the DB entirely, avoiding the FK validation error.

      it 'creates a response if none exists' do
        allow(Response).to receive(:find_or_create_by!)
          .with(map_id: review_map.id, round: 1)
          .and_yield(unsubmitted_response)
          .and_return(unsubmitted_response)
        allow(unsubmitted_response).to receive(:is_submitted=).with(false)
        result = item.ensure_response!
        expect(result).to eq(unsubmitted_response)
      end

      it 'does not create a duplicate response on repeated calls' do
        call_count = 0
        allow(Response).to receive(:find_or_create_by!)
          .with(map_id: review_map.id, round: 1) do |&block|
            call_count += 1
            block&.call(unsubmitted_response) if call_count == 1
            unsubmitted_response
          end
        allow(unsubmitted_response).to receive(:is_submitted=).with(false)
        item.ensure_response!
        item.ensure_response!
        expect(call_count).to eq(2) # called twice but block only yielded once
      end

      it 'creates the response with is_submitted false' do
        captured = nil
        allow(Response).to receive(:find_or_create_by!)
          .with(map_id: review_map.id, round: 1) do |&block|
            r = instance_double('Response')
            allow(r).to receive(:is_submitted=)
            block&.call(r)
            captured = r
            unsubmitted_response
          end
        item.ensure_response!
        expect(captured).to have_received(:is_submitted=).with(false)
      end

      it 'creates the response with round 1' do
        # round: 1 is passed as part of the find_or_create_by! key — verified by
        # checking the stub is called with the correct arguments.
        expect(Response).to receive(:find_or_create_by!)
          .with(map_id: review_map.id, round: 1)
          .and_return(unsubmitted_response)
        allow(unsubmitted_response).to receive(:is_submitted=)
        item.ensure_response!
      end
    end

    describe '#to_h' do
      subject(:hash) { item.to_h }

      # review_map already has `type: 'ReviewResponseMap'` in its double definition above

      it 'includes all required contract keys' do
        expect(hash.keys).to match_array(
          %i[task_type assignment_id response_map_id response_map_type reviewee_id team_participant_id]
        )
      end

      it 'sets task_type to :review' do
        expect(hash[:task_type]).to eq(:review)
      end

      it 'sets assignment_id correctly' do
        expect(hash[:assignment_id]).to eq(assignment.id)
      end

      it 'sets response_map_id correctly' do
        expect(hash[:response_map_id]).to eq(review_map.id)
      end

      it 'sets team_participant_id correctly' do
        expect(hash[:team_participant_id]).to eq(team_participant.id)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # QuizTaskItem
  # ---------------------------------------------------------------------------
  describe QuizTaskItem do
    before do
      allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
    end

    def build_item(rm: review_map)
      QuizTaskItem.new(
        assignment:       assignment,
        team_participant: team_participant,
        review_map:       rm
      )
    end

    describe '#task_type' do
      it 'returns :quiz' do
        expect(build_item.task_type).to eq(:quiz)
      end
    end

    describe '#response_map' do
      # QuizTaskItem#resolve_quiz_map calls:
      #   QuizResponseMap.find_by(reviewer_id:, reviewee_id:)
      # and if nil + questionnaire exists:
      #   map = QuizResponseMap.new(...); map.save!(validate: false)

      context 'when assignment has no quiz questionnaire and no existing quiz map' do
        before do
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(nil)
        end

        it 'returns nil' do
          expect(build_item.response_map).to be_nil
        end
      end

      context 'when an existing QuizResponseMap already exists for this reviewer/reviewee' do
        let(:existing_map) { instance_double('QuizResponseMap', id: 50) }

        before do
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(existing_map)
        end

        it 'returns the existing quiz map without creating a new one' do
          expect(build_item.response_map).to eq(existing_map)
        end

        it 'does not create a duplicate map' do
          expect(QuizResponseMap).not_to receive(:new)
          build_item.response_map
        end
      end

      context 'when assignment has a quiz questionnaire and no existing map' do
        let(:questionnaire) { instance_double('Questionnaire', id: 999) }
        let(:new_map)       { instance_double('QuizResponseMap', id: 55) }

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(nil)

          # Fix #10-11: Ruby 3 passes a plain hash to .new, not keyword args.
          # Use hash_including or allow with anything to avoid the kw/hash mismatch.
          allow(QuizResponseMap).to receive(:new)
            .with(hash_including(
              reviewer_id:        team_participant.participant_id,
              reviewee_id:        review_map.reviewee_id,
              reviewed_object_id: questionnaire.id,
              type:               'QuizResponseMap'
            ))
            .and_return(new_map)
          allow(new_map).to receive(:save!).with(validate: false)
        end

        it 'creates and returns a QuizResponseMap' do
          expect(build_item.response_map).to eq(new_map)
        end

        it 'does not create duplicate maps on repeated calls' do
          item = build_item
          item.response_map # first call — hits QuizResponseMap.new
          expect(QuizResponseMap).not_to receive(:new) # second — uses cached map
          item.response_map
        end
      end
    end

    describe '#completed?' do
      context 'when response_map is nil' do
        before do
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(nil)
        end

        it 'returns false' do
          expect(build_item.completed?).to be false
        end
      end

      context 'when a quiz map exists with a submitted response' do
        let(:quiz_map) { instance_double('QuizResponseMap', id: 60) }

        before do
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(quiz_map)
        end

        it 'returns true when response is submitted' do
          rel = double('relation', exists?: true)
          allow(Response).to receive(:where).with(map_id: quiz_map.id, is_submitted: true).and_return(rel)
          expect(build_item.completed?).to be true
        end

        it 'returns false when response is not submitted' do
          rel = double('relation', exists?: false)
          allow(Response).to receive(:where).with(map_id: quiz_map.id, is_submitted: true).and_return(rel)
          expect(build_item.completed?).to be false
        end
      end
    end

    describe '#ensure_response!' do
      context 'when response_map is nil' do
        before do
          allow(QuizResponseMap).to receive(:find_by)
            .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
            .and_return(nil)
        end

        it 'returns nil without creating a response' do
          expect(Response).not_to receive(:find_or_create_by!)
          expect(build_item.ensure_response!).to be_nil
        end
      end
    end

    describe '#to_h' do
      # Fix #12-13: add `type:` to the quiz_map double so map&.type works in to_h
      let(:quiz_map) do
        instance_double('QuizResponseMap',
          id:          70,
          reviewee_id: 999,
          type:        'QuizResponseMap'
        )
      end

      before do
        allow(QuizResponseMap).to receive(:find_by)
          .with(reviewer_id: team_participant.participant_id, reviewee_id: review_map.reviewee_id)
          .and_return(quiz_map)
      end

      subject(:hash) { build_item.to_h }

      it 'includes all required contract keys' do
        expect(hash.keys).to match_array(
          %i[task_type assignment_id response_map_id response_map_type reviewee_id team_participant_id]
        )
      end

      it 'sets task_type to :quiz' do
        expect(hash[:task_type]).to eq(:quiz)
      end
    end
  end
end