# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SubmissionRecordsController, type: :controller do
  let(:student_user) { create(:student) }
  let(:assignment) { create(:assignment) }
  let(:assignment_team) { create(:assignment_team, parent_id: assignment.id) }
  let(:submission_record) { create(:submission_record, team_id: assignment_team.id) }

  before do
    assignment_team.users << student_user
  end

  describe 'GET #index' do

    context 'when user is student' do
      before { sign_in student_user }

      it 'assigns all submission records to @submission_records' do
        get :index, params: { team_id: assignment_team.id }
        expect(assigns(:submission_records)).to eq([submission_record])
      end

      it 'renders the index template' do
        get :index, params: { team_id: assignment_team.id }
        expect(response).to render_template('index')
      end
    end

    context 'when user is a student but not in the team' do
      let(:other_student) { create(:student) }
      before { sign_in other_student }

      it 'denies access' do
        get :index, params: { team_id: assignment_team.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not logged in' do
      it 'denies access' do
        get :index, params: { team_id: assignment_team.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end