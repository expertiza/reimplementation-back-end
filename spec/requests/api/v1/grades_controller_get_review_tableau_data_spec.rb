require 'rails_helper'

RSpec.describe GradesController, type: :controller do
  let(:assignment_id) { "10" }
  let(:participant_id) { "20" }

  # Fake User
  let(:user) { instance_double(User, id: 99, name: "ReviewerUser", full_name: "Reviewer User") }

  # Fake AssignmentParticipant
  let(:fake_participant) do
    double("AssignmentParticipant", id: participant_id.to_i, user_id: user.id, user: user, handle: "reviewer_handle").tap do |p|
      allow(p).to receive(:[]).with(:id).and_return(p.id)
      allow(p).to receive(:[]).with(:user_id).and_return(p.user_id)
      allow(p).to receive(:[]).with(:handle).and_return(p.handle)
    end
  end

  # Fake Assignment
  let(:assignment) { instance_double(Assignment, id: assignment_id.to_i, name: "Test Assignment") }

  # Fake AssignmentQuestionnaire
  let(:fake_questionnaire) do
    double("AssignmentQuestionnaire", used_in_round: 1, questionnaire_id: 999).tap do |q|
      allow(q).to receive(:[]).with(:used_in_round).and_return(1)
      allow(q).to receive(:[]).with(:questionnaire_id).and_return(999)
    end
  end

  # Fake Item
  let(:fake_item) do
    double("Item", id: 1, txt: "Criterion 1", question_type: "Scale").tap do |item|
      allow(item).to receive(:[]).with(:id).and_return(item.id)
      allow(item).to receive(:[]).with(:txt).and_return(item.txt)
      allow(item).to receive(:[]).with(:question_type).and_return(item.question_type)
    end
  end

  # Fake ReviewResponseMap
  let(:fake_response_map) { instance_double(ReviewResponseMap, id: 555) }

  # Fake Response
  let(:fake_response) { instance_double(Response, id: 777, round: 1) }

  # Fake Answer
  let(:fake_answer) { instance_double(Answer, answer: 4, comments: "Good work") }

  # Expected JSON keys
  let(:expected_json_keys) { %w[responses_by_round participant assignment] }

  before do
    # Stub ActiveRecord finders
    allow(Assignment).to receive(:find).with(assignment_id).and_return(assignment)
    allow(AssignmentParticipant).to receive(:find).with(participant_id).and_return(fake_participant)

    # Stub AssignmentQuestionnaire query
    fake_relation = double("ActiveRecord::Relation")
    allow(fake_relation).to receive(:find_each).and_yield(fake_questionnaire)
    allow(AssignmentQuestionnaire).to receive(:where)
                                        .with("assignment_id = #{assignment_id}")
                                        .and_return(fake_relation)

    # Stub Item query
    fake_item_relation = double("ActiveRecord::Relation")
    allow(fake_item_relation).to receive(:find_each).and_yield(fake_item)
    allow(Item).to receive(:where).with("questionnaire_id = 999").and_return(fake_item_relation)

    # Use simple hashes instead of instance_double for hash-style access
    fake_response_map = { id: 555 }
    fake_response     = { id: 777, round: 1 }
    fake_item         = { id: 1, txt: "Criterion 1", question_type: "Scale" }
    fake_answer       = { answer: 4, comments: "Good work" }

    # Stub ReviewResponseMap.where(...).find_each
    fake_review_map_relation = double("ActiveRecord::Relation")
    allow(fake_review_map_relation).to receive(:find_each).and_yield(fake_response_map)
    allow(ReviewResponseMap).to receive(:where)
                                  .with("reviewed_object_id = #{assignment_id} AND reviewer_id = #{participant_id}")
                                  .and_return(fake_review_map_relation)

    # Stub Response.where(...).find_each
    fake_response_relation = double("ActiveRecord::Relation")
    allow(fake_response_relation).to receive(:find_each).and_yield(fake_response)
    allow(Response).to receive(:where)
                         .with("map_id = #{fake_response_map[:id]}")
                         .and_return(fake_response_relation)

    # Stub Answer.find_by(...)
    allow(Answer).to receive(:find_by)
                       .with(item_id: fake_item[:id], response_id: fake_response[:id])
                       .and_return(fake_answer)

    # Controller authorization stubs
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:action_allowed?).and_return(true)

    allow(controller).to receive(:get_items_from_questionnaire).and_return(
      {
        1 => {
          answers: {
            values: [],
            comments: []
          }
        }
      }
    )

    # Stub JWT decoding (if using token auth)
    request.headers['Authorization'] = 'Bearer faketoken'
    allow(JsonWebToken).to receive(:decode).and_return({ id: user.id })
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe "GET #get_review_tableau_data" do
    it "responds with valid JSON containing required keys" do
      get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to include(*expected_json_keys)
    end

    it "returns 404 if participant is not found" do
      allow(AssignmentParticipant).to receive(:find).with(participant_id).and_raise(ActiveRecord::RecordNotFound)

      get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to match(/Participant or assignment not found/)
    end

    it "returns 404 if assignment is not found" do
      allow(Assignment).to receive(:find).with(assignment_id).and_raise(ActiveRecord::RecordNotFound)

      get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to match(/Participant or assignment not found/)
    end

    it "returns participant info correctly" do
      get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

      json = JSON.parse(response.body)
      participant_json = json["participant"]
      expect(participant_json["id"]).to eq(fake_participant.id)
      expect(participant_json["user_id"]).to eq(fake_participant.user_id)
      expect(participant_json["user_name"]).to eq(fake_participant.user.name)
      expect(participant_json["full_name"]).to eq(fake_participant.user.full_name)
      expect(participant_json["handle"]).to eq(fake_participant.handle)
    end

    it "returns assignment info correctly" do
      get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

      json = JSON.parse(response.body)
      assignment_json = json["assignment"]
      expect(assignment_json["id"]).to eq(assignment.id)
      expect(assignment_json["name"]).to eq(assignment.name)
    end

    context "when user is a student (forbidden)" do
      let(:student_user) { instance_double(User, id: 50, name: "StudentUser", full_name: "Student User", role_id: 1) }

      before do
        allow(controller).to receive(:current_user).and_return(student_user)
        # allow(controller).to receive(:action_allowed?).and_return(false) # unauthorized
        allow(controller).to receive(:authorize).and_call_original
        allow(controller).to receive(:all_actions_allowed?).and_return(false)
      end

      it "returns 403 Unauthorized" do
        get :get_review_tableau_data, params: { assignment_id: assignment_id, participant_id: participant_id }

        expect(response).to have_http_status(:forbidden)

        json = JSON.parse(response.body)
        expect(json["error"]).to match(/You are not authorized to get_review_tableau_data this grades/)
      end
    end
  end
end
