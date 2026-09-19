require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Course Reports API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) do
    User.create!(
      name: 'instructor',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor Name',
      email: 'instructor@example.com'
    )
  end

  let(:student1) do
    User.create!(name: 'student1', password_digest: 'pw', role_id: @roles[:student].id,
                 full_name: 'Student One', email: 's1@example.com')
  end

  let(:student2) do
    User.create!(name: 'student2', password_digest: 'pw', role_id: @roles[:student].id,
                 full_name: 'Student Two', email: 's2@example.com')
  end

  let(:institution) { Institution.create!(name: 'NCSU') }

  let(:course) { create(:course, instructor: instructor, institution: institution) }

  let(:assignment) do
    Assignment.create!(name: 'Assignment A', course: course, instructor_id: instructor.id,
                       is_calibrated: false)
  end

  let(:calibrated_assignment) do
    Assignment.create!(name: 'Calibration Assignment', course: course,
                       instructor_id: instructor.id, is_calibrated: true)
  end

  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  # -----------------------------------------------------------------------
  # Helpers
  # -----------------------------------------------------------------------

  def create_participant(user, asgn)
    AssignmentParticipant.create!(user: user, parent_id: asgn.id, handle: user.name)
  end

  def create_team_for(user, asgn, grade: nil)
    team = AssignmentTeam.create!(name: "Team #{user.name}", parent_id: asgn.id,
                                  grade_for_submission: grade)
    TeamsParticipant.create!(team: team, user: user,
                             participant: AssignmentParticipant.find_by(user: user, parent_id: asgn.id))
    team
  end

  # -----------------------------------------------------------------------
  # GET /courses/:id/course_report/grade_summary
  # -----------------------------------------------------------------------

  describe 'GET /courses/:id/course_report/grade_summary' do
    context 'when the course has no assignments' do
      it 'returns empty rows' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['rows']).to be_empty
        expect(body['assignments']).to be_empty
      end
    end

    context 'when a calibrated assignment exists' do
      before do
        calibrated_assignment
        create_participant(student1, calibrated_assignment)
      end

      it 'includes calibrated assignments in the report' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        assignment_ids = body['assignments'].map { |a| a['id'] }
        expect(assignment_ids).to include(calibrated_assignment.id)
      end
    end

    context 'when an assignment has no participants' do
      before { assignment }

      it 'excludes assignments with no participants' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        assignment_ids = body['assignments'].map { |a| a['id'] }
        expect(assignment_ids).not_to include(assignment.id)
      end
    end

    context 'with a student enrolled in an assignment' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment, grade: nil)
      end

      it 'returns the student row with nil instructor_grade' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        expect(row).not_to be_nil
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        expect(cell['instructor_grade']).to be_nil
        expect(row['final_grade']).to be_nil
      end
    end

    context 'when a team has a grade_for_submission' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment, grade: 85)
      end

      it 'returns the instructor_grade for the student' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        expect(cell['instructor_grade']).to eq(85)
      end

      it 'populates final_grade as the sum of instructor grades' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        expect(row['final_grade']).to eq(85)
      end
    end

    context 'when a penalised grade reduces to zero' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment, grade: 0)
      end

      it 'includes a zero instructor_grade in final_grade rather than treating it as missing' do
        # Without the fix (reject(&:zero?)), final_grade would be nil. With the fix it is 0.
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        expect(cell['instructor_grade']).to eq(0)
        expect(row['final_grade']).to eq(0)
      end
    end

    context 'with multiple assignments' do
      let(:assignment2) do
        Assignment.create!(name: 'Assignment B', course: course,
                           instructor_id: instructor.id, is_calibrated: false)
      end

      before do
        create_participant(student1, assignment)
        create_participant(student1, assignment2)
        create_team_for(student1, assignment, grade: 80)
        create_team_for(student1, assignment2, grade: 90)
      end

      it 'sums instructor grades across assignments for final_grade' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        expect(row['final_grade']).to eq(170)
      end
    end

    context 'response structure' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment)
      end

      it 'returns course_id, course_name, assignments and rows' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        expect(body.keys).to include('course_id', 'course_name', 'assignments', 'rows')
        expect(body['course_id']).to eq(course.id)
        expect(body['course_name']).to eq(course.name)
      end
    end

    context 'when course does not exist' do
      it 'returns 404' do
        get "/courses/0/course_report/grade_summary", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    # ------------------------------------------------------------------
    # has_topics flag
    # ------------------------------------------------------------------

    context 'has_topics flag in assignments response' do
      before { create_participant(student1, assignment) }

      it 'returns has_topics: false when the assignment has no project topics' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        a = body['assignments'].find { |x| x['id'] == assignment.id }
        expect(a['has_topics']).to be false
      end

      it 'returns has_topics: true when the assignment has at least one project topic' do
        ProjectTopic.create!(assignment: assignment, topic_name: 'Topic A', max_choosers: 3)
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        a = body['assignments'].find { |x| x['id'] == assignment.id }
        expect(a['has_topics']).to be true
      end
    end

    # ------------------------------------------------------------------
    # Weighted peer scores (precompute_peer_scores)
    # ------------------------------------------------------------------

    context 'peer_score with unweighted reviewers (no ReviewGrade)' do
      let(:questionnaire) { Questionnaire.create!(name: 'Q1', instructor_id: instructor.id, min_question_score: 0, max_question_score: 5) }

      before do
        create_participant(student1, assignment)
        team = create_team_for(student1, assignment)

        reviewer_user = User.create!(name: 'reviewer1', password_digest: 'pw',
                                     role_id: @roles[:student].id, full_name: 'R1',
                                     email: 'r1@example.com')
        reviewer_ap = AssignmentParticipant.create!(user: reviewer_user, parent_id: assignment.id, handle: 'r1')

        item = questionnaire.items.create!(txt: 'Q', seq: 1, question_type: 'Scale', weight: 1, break_before: true)
        AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire,
                                         used_in_round: 1, questionnaire_weight: 100)
        map = ReviewResponseMap.create!(reviewed_object_id: assignment.id,
                                        reviewer_id: reviewer_ap.id, reviewee_id: team.id)
        resp = Response.create!(map_id: map.id, is_submitted: true, round: 1)
        Answer.create!(response: resp, item: item, answer: 4)
      end

      it 'returns a non-nil peer_score for the student' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        expect(cell['peer_score']).not_to be_nil
      end
    end

    context 'peer_score with a weighted reviewer (ReviewGrade present)' do
      let(:questionnaire) { Questionnaire.create!(name: 'Q2', instructor_id: instructor.id, min_question_score: 0, max_question_score: 5) }

      before do
        create_participant(student1, assignment)
        team = create_team_for(student1, assignment)

        reviewer_user = User.create!(name: 'reviewer2', password_digest: 'pw',
                                     role_id: @roles[:student].id, full_name: 'R2',
                                     email: 'r2@example.com')
        reviewer_ap = AssignmentParticipant.create!(user: reviewer_user, parent_id: assignment.id, handle: 'r2')
        ReviewGrade.create!(participant: reviewer_ap, grade_for_reviewer: 2.0, grader_id: instructor.id)

        item = questionnaire.items.create!(txt: 'Q', seq: 1, question_type: 'Scale', weight: 1, break_before: true)
        AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire,
                                         used_in_round: 1, questionnaire_weight: 100)
        map = ReviewResponseMap.create!(reviewed_object_id: assignment.id,
                                        reviewer_id: reviewer_ap.id, reviewee_id: team.id)
        resp = Response.create!(map_id: map.id, is_submitted: true, round: 1)
        Answer.create!(response: resp, item: item, answer: 5)
      end

      it 'returns a peer_score weighted by the reviewer grade' do
        get "/courses/#{course.id}/course_report/grade_summary", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        # score 5/5 = 100%, weighted by grade 2.0 — still 100
        expect(cell['peer_score']).to eq(100.0)
      end
    end
  end

  # -----------------------------------------------------------------------
  # GET /courses/:id/course_report/all_reviews
  # -----------------------------------------------------------------------

  describe 'GET /courses/:id/course_report/all_reviews' do
    context 'when the course has no assignments' do
      it 'returns empty rows' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        expect(body['rows']).to be_empty
      end
    end

    context 'when a calibrated assignment exists' do
      before do
        calibrated_assignment
        create_participant(student1, calibrated_assignment)
      end

      it 'includes calibrated assignments' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        assignment_ids = body['assignments'].map { |a| a['id'] }
        expect(assignment_ids).to include(calibrated_assignment.id)
      end
    end

    context 'with a student enrolled in an assignment' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment)
      end

      it 'returns a row for the student with nil teammate_review when no reviews exist' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        expect(row).not_to be_nil
        cell = row['assignments'].find { |c| c['assignment_id'] == assignment.id }
        expect(cell['teammate_review']).to be_nil
        expect(row['aggregate']).to be_nil
      end

      it 'returns teammate_count of 0 when student has no teammates' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        row = body['rows'].find { |r| r['user_id'] == student1.id }
        expect(row['teammate_count']).to eq(0)
      end
    end

    context 'with two students on the same team' do
      before do
        create_participant(student1, assignment)
        create_participant(student2, assignment)
        team = AssignmentTeam.create!(name: 'Team AB', parent_id: assignment.id)
        ap1 = AssignmentParticipant.find_by(user: student1, parent_id: assignment.id)
        ap2 = AssignmentParticipant.find_by(user: student2, parent_id: assignment.id)
        TeamsParticipant.create!(team: team, user: student1, participant: ap1)
        TeamsParticipant.create!(team: team, user: student2, participant: ap2)
      end

      it 'returns teammate_count of 1 for each student' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        row1 = body['rows'].find { |r| r['user_id'] == student1.id }
        row2 = body['rows'].find { |r| r['user_id'] == student2.id }
        expect(row1['teammate_count']).to eq(1)
        expect(row2['teammate_count']).to eq(1)
      end
    end

    context 'response structure' do
      before do
        create_participant(student1, assignment)
        create_team_for(student1, assignment)
      end

      it 'includes course_id, course_name, assignments and rows' do
        get "/courses/#{course.id}/course_report/all_reviews", headers: headers
        body = JSON.parse(response.body)
        expect(body.keys).to include('course_id', 'course_name', 'assignments', 'rows')
      end
    end

    context 'when course does not exist' do
      it 'returns 404' do
        get "/courses/0/course_report/all_reviews", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
