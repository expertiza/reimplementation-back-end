require 'rails_helper'
require 'json_web_token'

RSpec.describe 'AssignmentsTopicsController', type: :request do
  include RolesHelper
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor_user) { create(:user, :instructor) }
  let!(:instructor) { Instructor.find(instructor_user.id) }
  let!(:assignment) { create(:assignment, instructor:, vary_by_topic: true, vary_by_round: vary_by_round, rounds_of_reviews: 2) }
  let!(:topic_a) { create(:project_topic, assignment:, topic_name: 'Topic A', topic_identifier: 'A') }
  let!(:topic_b) { create(:project_topic, assignment:, topic_name: 'Topic B', topic_identifier: 'B') }
  let!(:default_review_rubric) do
    create(:questionnaire, instructor:, questionnaire_type: 'ReviewQuestionnaire', name: 'Default Review Rubric')
  end
  let!(:topic_review_rubric) do
    create(:questionnaire, instructor:, questionnaire_type: 'ReviewQuestionnaire', name: 'Topic Review Rubric')
  end
  let!(:round_two_rubric) do
    create(:questionnaire, instructor:, questionnaire_type: 'ReviewQuestionnaire', name: 'Round 2 Review Rubric')
  end
  let(:vary_by_round) { false }
  let(:headers) { { 'Authorization' => "Bearer #{JsonWebToken.encode({ id: instructor.id })}" } }

  before do
    create(:assignment_questionnaire, assignment:, questionnaire: default_review_rubric, used_in_round: default_round)
  end

  describe 'GET /assignments/:assignment_id/topics/rubrics' do
    let(:default_round) { nil }

    it 'returns topic-specific effective rubrics with assignment fallback' do
      topic_a.assign_rubric!(questionnaire_type: 'ReviewQuestionnaire', questionnaire_id: topic_review_rubric.id)

      get "/assignments/#{assignment.id}/topics/rubrics", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      topic_a_payload = body.fetch('topics').find { |topic| topic['id'] == topic_a.id }
      topic_b_payload = body.fetch('topics').find { |topic| topic['id'] == topic_b.id }

      expect(topic_a_payload.dig('rubric_assignments', 0, 'questionnaire_id')).to eq(topic_review_rubric.id)
      expect(topic_a_payload.dig('rubric_assignments', 0, 'effective_questionnaire_id')).to eq(topic_review_rubric.id)
      expect(topic_b_payload.dig('rubric_assignments', 0, 'questionnaire_id')).to be_nil
      expect(topic_b_payload.dig('rubric_assignments', 0, 'effective_questionnaire_id')).to eq(default_review_rubric.id)
    end
  end

  describe 'PATCH /assignments/:assignment_id/topics/rubrics' do
    context 'when rubrics vary only by topic' do
      let(:default_round) { nil }

      it 'persists topic-specific mappings without recreating defaults' do
        expect do
          patch "/assignments/#{assignment.id}/topics/rubrics",
                params: {
                  rubric_mappings: [
                    { topic_id: topic_a.id, questionnaire_id: topic_review_rubric.id }
                  ]
                },
                headers: headers
        end.to change { AssignmentQuestionnaire.where(assignment:, topic_id: topic_a.id).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(assignment.reload.default_rubric_mapping_for(questionnaire_type: 'ReviewQuestionnaire', round: nil)&.questionnaire_id)
          .to eq(default_review_rubric.id)
        expect(topic_a.reload.rubric_for_review&.id).to eq(topic_review_rubric.id)
      end
    end

    context 'when rubrics vary by topic and round' do
      let(:vary_by_round) { true }
      let(:default_round) { 1 }

      before do
        create(:assignment_questionnaire, assignment:, questionnaire: round_two_rubric, used_in_round: 2)
      end

      it 'stores independent mappings per topic and round with round-aware fallback' do
        patch "/assignments/#{assignment.id}/topics/rubrics",
              params: {
                rubric_mappings: [
                  { topic_id: topic_a.id, questionnaire_id: topic_review_rubric.id, used_in_round: 1 },
                  { topic_id: topic_a.id, questionnaire_id: round_two_rubric.id, used_in_round: 2 }
                ]
              },
              headers: headers

        expect(response).to have_http_status(:ok)
        expect(topic_a.reload.rubric_for_review(round: 1)&.id).to eq(topic_review_rubric.id)
        expect(topic_a.reload.rubric_for_review(round: 2)&.id).to eq(round_two_rubric.id)
        expect(topic_b.reload.rubric_for_review(round: 1)&.id).to eq(default_review_rubric.id)
        expect(topic_b.reload.rubric_for_review(round: 2)&.id).to eq(round_two_rubric.id)
      end
    end
  end
end
