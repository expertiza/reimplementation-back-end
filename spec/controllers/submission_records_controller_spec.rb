# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionRecordsController, type: :controller do
  let(:student_user) { create(:student) }
  let(:assignment) { create(:assignment) }
  let(:submission_record) { create(:submission_record) }

  describe 'GET #index' do
    context 'user is student' do
      before do
        sign_in student_user
        get :index
      end

      it 'renders student view' do
        expect(response).to render_template('student_task/list')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is a student but not in the team' do
      let(:other_student) { create(:student) }
      before { sign_in other_student }

      it 'denies access' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not logged in' do
      before { get :index }

      it 'denies access' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
