require 'rails_helper'

RSpec.describe QuestionnairesController, type: :controller do
  before do
    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe 'PATCH #update' do
    it 'archives and resets affected reviews when a review questionnaire is updated' do
      assignment = create(:assignment)
      topic = create(:project_topic, assignment: assignment)
      reviewee_team = AssignmentTeam.create!(name: 'Security Team', parent_id: assignment.id, type: 'AssignmentTeam')
      reviewer_user = create(:user, :student)
      reviewer = AssignmentParticipant.create!(
        user: reviewer_user,
        parent_id: assignment.id,
        type: 'AssignmentParticipant',
        handle: reviewer_user.name
      )
      instructor = assignment.instructor.becomes(Instructor)
      questionnaire = Questionnaire.create!(
        name: 'Review Rubric',
        instructor: instructor,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Review',
        min_question_score: 0,
        max_question_score: 5
      )
      AssignmentQuestionnaire.create!(
        assignment: assignment,
        questionnaire: questionnaire,
        project_topic: topic,
        used_in_round: 1
      )
      review_map = ReviewResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: reviewer.id,
        reviewee_id: reviewee_team.id,
        type: 'ReviewResponseMap'
      )
      review_response = Response.create!(map_id: review_map.id, round: 1, is_submitted: true, additional_comment: 'Old review')
      SignedUpTeam.create!(project_topic: topic, team: reviewee_team, is_waitlisted: false)

      delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      parameterized_mailer = double('RubricUpdateMailer::Parameterized', review_redo_notification: delivery)
      allow(RubricUpdateMailer).to receive(:with).and_return(parameterized_mailer)

      expect do
        patch :update,
              params: {
                id: questionnaire.id,
                questionnaire: {
                  name: 'Updated Review Rubric'
                }
              },
              format: :json
      end.to change(ReviewResetArchive, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(Response.exists?(review_response.id)).to be(false)
      expect(ReviewResetArchive.last.reset_reason).to eq('questionnaire_updated')
      expect(ReviewResetArchive.last.snapshot_data['response']['additional_comment']).to eq('Old review')
      expect(delivery).to have_received(:deliver_later)
    end
  end
end
