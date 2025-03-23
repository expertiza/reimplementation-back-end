# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SubmissionRecordsController, type: :controller do
  # pulling assumptions from factorybots.
  # A mock student and assignment have already been created to generate a submission record.
  let(:student_user) { create(:student) } # TODO check this is set up correctly
  let(:assignment) { create(:assignment) } # TODO check this is set up correctly
  let(:submission_record) { create(:submission_record) } # TODO check this is set up correctly

  describe 'GET #index' do

    # only testing for when user is a student, assume existing functionality already works
    # expected output: when user is a student the submission records should be accessed successfully
    context "user is student" do
      before do
        sign_in student_user
        get :index
      end

      it "renders student view" do
        expect(response).to render_template("student_task/list")
      end
    end

      # it 'renders the index template' do
      # get :index, params: { team_id: assignment_team.id }
      # expect(response).to render_template('index')
      # end

      # goal: ensure that other students cannot view another submission record
    context 'when user is a student but not in the team' do
      let(:other_student) { create(:student) } # create other student that is not in the team
      before { sign_in other_student }

      it 'denies access' do
        expect(response).to have_http_status(:forbidden)
      end
    end
    # goal: denies access if user is not logged in
    context 'when user is not logged in' do
      before {get :index }
      it 'denies access' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end



