require 'swagger_helper'
require 'json_web_token'
require 'json'

RSpec.describe 'Course Reports API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) do
    User.create!(
      name: 'instructor_records',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor Records',
      email: 'instructor_records@example.com'
    )
  end

  let(:student) do
    User.create!(
      name: 'student_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student Records',
      email: 'student_records@example.com'
    )
  end

  let(:teammate) do
    User.create!(
      name: 'teammate_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Teammate Records',
      email: 'teammate_records@example.com'
    )
  end

  let(:other_student) do
    User.create!(
      name: 'other_student_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Other Student Records',
      email: 'other_student_records@example.com'
    )
  end

  let(:reviewer_one) do
    User.create!(
      name: 'reviewer_one_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Reviewer One Records',
      email: 'reviewer_one_records@example.com'
    )
  end

  let(:reviewer_two) do
    User.create!(
      name: 'reviewer_two_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Reviewer Two Records',
      email: 'reviewer_two_records@example.com'
    )
  end

  let(:assignment2_partner) do
    User.create!(
      name: 'assignment2_partner_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Assignment2 Partner Records',
      email: 'assignment2_partner_records@example.com'
    )
  end

  let(:assignment2_reviewer) do
    User.create!(
      name: 'assignment2_reviewer_records',
      password_digest: 'password',
      role_id: @roles[:student].id,
      full_name: 'Assignment2 Reviewer Records',
      email: 'assignment2_reviewer_records@example.com'
    )
  end

  let(:outside_instructor) do
    User.create!(
      name: 'outside_instructor_records',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Outside Instructor Records',
      email: 'outside_instructor_records@example.com'
    )
  end

  let!(:course) { create(:course, instructor: instructor) }

  let!(:assignment) do
    Assignment.create!(
      name: 'Assignment With Records',
      instructor_id: instructor.id,
      course_id: course.id,
      has_topics: true
    )
  end

  let!(:assignment2) do
    Assignment.create!(
      name: 'Assignment Without Topics',
      instructor_id: instructor.id,
      course_id: course.id,
      has_topics: false
    )
  end

  let!(:other_course) { create(:course) }

  let!(:assignment3) do
    Assignment.create!(
      name: 'Assignment Outside Course',
      instructor_id: instructor.id,
      course_id: other_course.id,
      has_topics: false
    )
  end

  let!(:team) { AssignmentTeam.create!(name: 'Records Team', parent_id: assignment.id, grade_for_submission: 91) }
  let!(:team2) { AssignmentTeam.create!(name: 'Records Team 2', parent_id: assignment2.id, grade_for_submission: 84) }
  let!(:team3) { AssignmentTeam.create!(name: 'Records Team 3', parent_id: assignment3.id, grade_for_submission: 73) }
  let!(:review_team) { AssignmentTeam.create!(name: 'Review Team', parent_id: assignment.id, grade_for_submission: 88) }
  let!(:assignment2_review_team) { AssignmentTeam.create!(name: 'Assignment 2 Review Team', parent_id: assignment2.id, grade_for_submission: 79) }

  let!(:participant) { AssignmentParticipant.create!(user_id: student.id, parent_id: assignment.id, handle: student.name) }
  let!(:participant2) { AssignmentParticipant.create!(user_id: teammate.id, parent_id: assignment.id, handle: teammate.name) }
  let!(:participant3) { AssignmentParticipant.create!(user_id: other_student.id, parent_id: assignment2.id, handle: other_student.name) }
  let!(:participant4) { AssignmentParticipant.create!(user_id: other_student.id, parent_id: assignment3.id, handle: other_student.name) }
  let!(:participant5) { AssignmentParticipant.create!(user_id: reviewer_one.id, parent_id: assignment.id, handle: reviewer_one.name) }
  let!(:participant6) { AssignmentParticipant.create!(user_id: reviewer_two.id, parent_id: assignment.id, handle: reviewer_two.name) }
  let!(:participant7) { AssignmentParticipant.create!(user_id: assignment2_partner.id, parent_id: assignment2.id, handle: assignment2_partner.name) }
  let!(:participant8) { AssignmentParticipant.create!(user_id: assignment2_reviewer.id, parent_id: assignment2.id, handle: assignment2_reviewer.name) }
  let!(:participant9) { AssignmentParticipant.create!(user_id: student.id, parent_id: assignment2.id, handle: student.name) }
  let!(:participant10) { AssignmentParticipant.create!(user_id: teammate.id, parent_id: assignment2.id, handle: teammate.name) }
  let!(:participant11) { AssignmentParticipant.create!(user_id: other_student.id, parent_id: assignment.id, handle: other_student.name) }
  let!(:participant12) { AssignmentParticipant.create!(user_id: reviewer_one.id, parent_id: assignment2.id, handle: reviewer_one.name) }
  let!(:participant13) { AssignmentParticipant.create!(user_id: reviewer_two.id, parent_id: assignment2.id, handle: reviewer_two.name) }
  let!(:participant14) { AssignmentParticipant.create!(user_id: assignment2_partner.id, parent_id: assignment.id, handle: assignment2_partner.name) }
  let!(:participant15) { AssignmentParticipant.create!(user_id: assignment2_reviewer.id, parent_id: assignment.id, handle: assignment2_reviewer.name) }

  let!(:topic) { ProjectTopic.create!(assignment_id: assignment.id, topic_name: 'Topic Alpha', topic_identifier: 'T1', max_choosers: 2) }
  let!(:signed_up_team) { SignedUpTeam.create!(team_id: team.id, project_topic_id: topic.id, is_waitlisted: false) }
  let!(:signed_up_review_team) { SignedUpTeam.create!(team_id: review_team.id, project_topic_id: topic.id, is_waitlisted: false) }

  let!(:questionnaire1) do
    Questionnaire.create!(
      name: 'Assignment 1 Records Questionnaire',
      instructor_id: instructor.id,
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: 'ReviewQuestionnaire'
    )
  end

  let!(:questionnaire2) do
    Questionnaire.create!(
      name: 'Assignment 2 Records Questionnaire',
      instructor_id: instructor.id,
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: 'ReviewQuestionnaire'
    )
  end

  let!(:criterion1) do
    Criterion.create!(
      questionnaire_id: questionnaire1.id,
      txt: 'Quality of contribution',
      weight: 1,
      seq: 1,
      question_type: 'Criterion',
      size: '50,3',
      break_before: true
    )
  end

  let!(:criterion2) do
    Criterion.create!(
      questionnaire_id: questionnaire2.id,
      txt: 'Quality of contribution',
      weight: 1,
      seq: 1,
      question_type: 'Criterion',
      size: '50,3',
      break_before: true
    )
  end

  let!(:assignment_questionnaire1) { AssignmentQuestionnaire.create!(assignment_id: assignment.id, questionnaire_id: questionnaire1.id) }
  let!(:assignment_questionnaire2) { AssignmentQuestionnaire.create!(assignment_id: assignment2.id, questionnaire_id: questionnaire2.id) }

  let!(:assignment_review_due_date1) do
    AssignmentDueDate.create!(
      parent: assignment,
      due_at: 12.days.from_now,
      deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
      submission_allowed_id: 3,
      review_allowed_id: 3
    )
  end

  let!(:assignment_review_due_date2) do
    AssignmentDueDate.create!(
      parent: assignment,
      due_at: 14.days.from_now,
      deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
      submission_allowed_id: 3,
      review_allowed_id: 3
    )
  end

  let!(:assignment2_review_due_date) do
    AssignmentDueDate.create!(
      parent: assignment2,
      due_at: 7.days.from_now,
      deadline_type_id: DueDate::REVIEW_DEADLINE_TYPE_ID,
      submission_allowed_id: 3,
      review_allowed_id: 3
    )
  end

  let!(:review_map1) { ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant5.id, reviewee_id: team.id) }
  let!(:review_map2) { ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant6.id, reviewee_id: team.id) }
  let!(:review_map3) { ReviewResponseMap.create!(reviewed_object_id: assignment2.id, reviewer_id: participant8.id, reviewee_id: team2.id) }
  let!(:review_map4) { ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant.id, reviewee_id: review_team.id) }
  let!(:review_map5) { ReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant2.id, reviewee_id: review_team.id) }
  let!(:review_map6) { ReviewResponseMap.create!(reviewed_object_id: assignment2.id, reviewer_id: participant9.id, reviewee_id: assignment2_review_team.id) }
  let!(:review_map7) { ReviewResponseMap.create!(reviewed_object_id: assignment2.id, reviewer_id: participant10.id, reviewee_id: assignment2_review_team.id) }

  let!(:review_response1) { Response.create!(map_id: review_map1.id, is_submitted: true) }
  let!(:review_response2) { Response.create!(map_id: review_map2.id, is_submitted: true) }
  let!(:review_response3) { Response.create!(map_id: review_map3.id, is_submitted: true) }
  let!(:review_response4) { Response.create!(map_id: review_map4.id, is_submitted: true) }
  let!(:review_response5) { Response.create!(map_id: review_map5.id, is_submitted: true) }
  let!(:review_response6) { Response.create!(map_id: review_map6.id, is_submitted: true) }
  let!(:review_response7) { Response.create!(map_id: review_map7.id, is_submitted: true) }

  let!(:review_answer1) { Answer.create!(response_id: review_response1.id, item_id: criterion1.id, answer: 4, comments: 'Strong work') }
  let!(:review_answer2) { Answer.create!(response_id: review_response2.id, item_id: criterion1.id, answer: 5, comments: 'Excellent work') }
  let!(:review_answer3) { Answer.create!(response_id: review_response3.id, item_id: criterion2.id, answer: 3, comments: 'Solid work') }
  let!(:review_answer4) { Answer.create!(response_id: review_response4.id, item_id: criterion1.id, answer: 2, comments: 'Needs more polish') }
  let!(:review_answer5) { Answer.create!(response_id: review_response5.id, item_id: criterion1.id, answer: 3, comments: 'Decent work') }
  let!(:review_answer6) { Answer.create!(response_id: review_response6.id, item_id: criterion2.id, answer: 4, comments: 'Very good effort') }
  let!(:review_answer7) { Answer.create!(response_id: review_response7.id, item_id: criterion2.id, answer: 5, comments: 'Excellent effort') }

  let!(:feedback_map1) { FeedbackResponseMap.create!(reviewed_object_id: review_map4.id, reviewer_id: participant11.id, reviewee_id: participant.id) }
  let!(:feedback_map2) { FeedbackResponseMap.create!(reviewed_object_id: review_map5.id, reviewer_id: participant14.id, reviewee_id: participant2.id) }
  let!(:feedback_map3) { FeedbackResponseMap.create!(reviewed_object_id: review_map6.id, reviewer_id: participant12.id, reviewee_id: participant9.id) }
  let!(:feedback_map4) { FeedbackResponseMap.create!(reviewed_object_id: review_map7.id, reviewer_id: participant13.id, reviewee_id: participant10.id) }

  let!(:feedback_response1) { Response.create!(map_id: feedback_map1.id, is_submitted: true) }
  let!(:feedback_response2) { Response.create!(map_id: feedback_map2.id, is_submitted: true) }
  let!(:feedback_response3) { Response.create!(map_id: feedback_map3.id, is_submitted: true) }
  let!(:feedback_response4) { Response.create!(map_id: feedback_map4.id, is_submitted: true) }

  let!(:feedback_answer1) { Answer.create!(response_id: feedback_response1.id, item_id: criterion1.id, answer: 4, comments: 'Helpful review') }
  let!(:feedback_answer2) { Answer.create!(response_id: feedback_response2.id, item_id: criterion1.id, answer: 5, comments: 'Excellent review') }
  let!(:feedback_answer3) { Answer.create!(response_id: feedback_response3.id, item_id: criterion2.id, answer: 3, comments: 'Useful review') }
  let!(:feedback_answer4) { Answer.create!(response_id: feedback_response4.id, item_id: criterion2.id, answer: 2, comments: 'Needs better review detail') }

  let!(:teammate_review_map1) { TeammateReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant2.id, reviewee_id: participant.id) }
  let!(:teammate_review_map2) { TeammateReviewResponseMap.create!(reviewed_object_id: assignment.id, reviewer_id: participant.id, reviewee_id: participant2.id) }
  let!(:teammate_review_map3) { TeammateReviewResponseMap.create!(reviewed_object_id: assignment2.id, reviewer_id: participant7.id, reviewee_id: participant3.id) }
  let!(:teammate_review_map4) { TeammateReviewResponseMap.create!(reviewed_object_id: assignment2.id, reviewer_id: participant3.id, reviewee_id: participant7.id) }

  let!(:teammate_response1) { Response.create!(map_id: teammate_review_map1.id, is_submitted: true) }
  let!(:teammate_response2) { Response.create!(map_id: teammate_review_map2.id, is_submitted: true) }
  let!(:teammate_response3) { Response.create!(map_id: teammate_review_map3.id, is_submitted: true) }
  let!(:teammate_response4) { Response.create!(map_id: teammate_review_map4.id, is_submitted: true) }

  let!(:teammate_answer1) { Answer.create!(response_id: teammate_response1.id, item_id: criterion1.id, answer: 3, comments: 'Good teammate') }
  let!(:teammate_answer2) { Answer.create!(response_id: teammate_response2.id, item_id: criterion1.id, answer: 4, comments: 'Reliable teammate') }
  let!(:teammate_answer3) { Answer.create!(response_id: teammate_response3.id, item_id: criterion2.id, answer: 2, comments: 'Needs improvement') }
  let!(:teammate_answer4) { Answer.create!(response_id: teammate_response4.id, item_id: criterion2.id, answer: 5, comments: 'Outstanding partner') }

  let(:instructor_token) { JsonWebToken.encode({ id: instructor.id }) }
  let(:student_token) { JsonWebToken.encode({ id: student.id }) }
  let(:outside_instructor_token) { JsonWebToken.encode({ id: outside_instructor.id }) }
  let(:Authorization) { "Bearer #{instructor_token}" }

  before do
    team.add_member(participant)
    team.add_member(participant2)
    review_team.add_member(participant11)
    review_team.add_member(participant14)
    review_team.add_member(participant15)
    team2.add_member(participant3)
    team2.add_member(participant7)
    team2.add_member(participant9)
    team2.add_member(participant10)
    team3.add_member(participant4)
    review_team.add_member(participant5)
    review_team.add_member(participant6)
    assignment2_review_team.add_member(participant8)
    assignment2_review_team.add_member(participant12)
    assignment2_review_team.add_member(participant13)
  end

  path '/course_reports' do
    get 'Retrieve a student-by-assignment table for a course' do
      tags 'Course Reports'
      produces 'application/json'
      security [bearer_auth: []]

      parameter name: :course_id, in: :query, type: :integer, required: true, description: 'ID of the course'
      parameter name: 'Authorization', in: :header, type: :string, required: true, description: 'Bearer token'

      response '200', 'Returns a student-by-assignment table for the course' do
        let(:course_id) { course.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          puts "\nCourse report stats:\n#{JSON.pretty_generate(data)}"

          expect(data['course_id']).to eq(course.id)
          expect(data['course_name']).to eq(course.name)
          expect(data.keys).to match_array(%w[course_id course_name assignments students])
          expect(data['assignments'].length).to eq(2)
          expect(data['assignments'].first.keys).to match_array(%w[assignment_id assignment_name has_topics])
          assignment_ids_ordered_by_final_review_deadline = [assignment, assignment2]
            .sort_by do |assignment_record|
              assignment_record.due_dates
                .select { |due_date| due_date.deadline_type_id == DueDate::REVIEW_DEADLINE_TYPE_ID }
                .map(&:due_at)
                .max
            end
            .map(&:id)

          expect(data['assignments'].map { |item| item['assignment_id'] }).to eq(
            assignment_ids_ordered_by_final_review_deadline
          )
          expect(assignment_review_due_date2.due_at).to be > assignment2_review_due_date.due_at
          expect(data['assignments'].last['assignment_id']).to eq(assignment.id)
          expect(data['assignments'].map { |item| item['assignment_name'] }).to match_array(['Assignment With Records', 'Assignment Without Topics'])
          expect(data['assignments'].find { |item| item['assignment_id'] == assignment.id }['has_topics']).to eq(true)
          expect(data['assignments'].find { |item| item['assignment_id'] == assignment2.id }['has_topics']).to eq(false)
          expect(data['students'].length).to eq(7)

          student_row = data['students'].find { |item| item['user_id'] == student.id }
          expect(student_row.keys).to match_array(%w[user_id user_name assignments])
          expect(student_row['user_name']).to eq(student.name)
          expect(student_row['assignments'].keys).to match_array([assignment.id.to_s, assignment2.id.to_s])
          expect(student_row['assignments'][assignment.id.to_s].keys).to match_array(
            %w[participant_id peer_grade instructor_grade avg_teammate_score avg_author_feedback_score topic]
          )
          expect(student_row['assignments'][assignment2.id.to_s].keys).to match_array(
            %w[participant_id peer_grade instructor_grade avg_teammate_score avg_author_feedback_score]
          )
          expect(student_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant.id)
          expect(student_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(90.0)
          expect(student_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(91)
          expect(student_row['assignments'][assignment.id.to_s]['avg_teammate_score']).to eq(60.0)
          expect(student_row['assignments'][assignment.id.to_s]['avg_author_feedback_score']).to eq(80.0)
          expect(student_row['assignments'][assignment.id.to_s]['topic']).to eq('Topic Alpha')
          expect(student_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant9.id)
          expect(student_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(60.0)
          expect(student_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(84)
          expect(student_row['assignments'][assignment2.id.to_s]['avg_author_feedback_score']).to eq(60.0)

          teammate_row = data['students'].find { |item| item['user_id'] == teammate.id }
          expect(teammate_row['user_name']).to eq(teammate.name)
          expect(teammate_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant2.id)
          expect(teammate_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(90.0)
          expect(teammate_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(91)
          expect(teammate_row['assignments'][assignment.id.to_s]['avg_teammate_score']).to eq(80.0)
          expect(teammate_row['assignments'][assignment.id.to_s]['avg_author_feedback_score']).to eq(100.0)
          expect(teammate_row['assignments'][assignment.id.to_s]['topic']).to eq('Topic Alpha')
          expect(teammate_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant10.id)
          expect(teammate_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(60.0)
          expect(teammate_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(84)
          expect(teammate_row['assignments'][assignment2.id.to_s]['avg_author_feedback_score']).to eq(40.0)

          other_student_row = data['students'].find { |item| item['user_id'] == other_student.id }
          expect(other_student_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant11.id)
          expect(other_student_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(50.0)
          expect(other_student_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(88)
          expect(other_student_row['assignments'][assignment.id.to_s]['avg_author_feedback_score']).to be_nil
          expect(other_student_row['assignments'][assignment.id.to_s]['topic']).to eq('Topic Alpha')
          expect(other_student_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant3.id)
          expect(other_student_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(60.0)
          expect(other_student_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(84)
          expect(other_student_row['assignments'][assignment2.id.to_s]['avg_teammate_score']).to eq(40.0)
          expect(other_student_row['assignments'][assignment2.id.to_s]).not_to have_key('topic')

          reviewer_row = data['students'].find { |item| item['user_id'] == reviewer_one.id }
          expect(reviewer_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant5.id)
          expect(reviewer_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(50.0)
          expect(reviewer_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(88)
          expect(reviewer_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant12.id)
          expect(reviewer_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(90.0)
          expect(reviewer_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(79)

          reviewer_two_row = data['students'].find { |item| item['user_id'] == reviewer_two.id }
          expect(reviewer_two_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant6.id)
          expect(reviewer_two_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(88)
          expect(reviewer_two_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(50.0)
          expect(reviewer_two_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant13.id)
          expect(reviewer_two_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(90.0)
          expect(reviewer_two_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(79)

          assignment2_partner_row = data['students'].find { |item| item['user_id'] == assignment2_partner.id }
          expect(assignment2_partner_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant14.id)
          expect(assignment2_partner_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(50.0)
          expect(assignment2_partner_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(88)
          expect(assignment2_partner_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant7.id)
          expect(assignment2_partner_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(60.0)
          expect(assignment2_partner_row['assignments'][assignment2.id.to_s]['avg_teammate_score']).to eq(100.0)

          assignment2_reviewer_row = data['students'].find { |item| item['user_id'] == assignment2_reviewer.id }
          expect(assignment2_reviewer_row['assignments'][assignment.id.to_s]['participant_id']).to eq(participant15.id)
          expect(assignment2_reviewer_row['assignments'][assignment.id.to_s]['peer_grade']).to eq(50.0)
          expect(assignment2_reviewer_row['assignments'][assignment.id.to_s]['instructor_grade']).to eq(88)
          expect(assignment2_reviewer_row['assignments'][assignment2.id.to_s]['participant_id']).to eq(participant8.id)
          expect(assignment2_reviewer_row['assignments'][assignment2.id.to_s]['peer_grade']).to eq(90.0)
          expect(assignment2_reviewer_row['assignments'][assignment2.id.to_s]['instructor_grade']).to eq(79)

          outside_course_ids = data['assignments'].map { |item| item['assignment_id'] }
          expect(outside_course_ids).not_to include(assignment3.id)
        end
      end

      response '404', 'Course not found' do
        let(:course_id) { 999_999 }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Course not found')
        end
      end

      response '500', 'Final assignment due date is not a review deadline' do
        let(:course_id) { course.id }

        let!(:assignment_submission_due_date) do
          AssignmentDueDate.create!(
            parent: assignment2,
            due_at: 21.days.from_now,
            deadline_type_id: 1,
            submission_allowed_id: 3,
            review_allowed_id: 3
          )
        end

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq(
            "Final due date for assignment #{assignment2.id} is not a review deadline"
          )
        end
      end

      response '403', 'Forbidden for students' do
        let(:course_id) { course.id }
        let(:Authorization) { "Bearer #{student_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to index this course_reports')
        end
      end

      response '403', 'Forbidden for instructors outside the course teaching staff' do
        let(:course_id) { course.id }
        let(:Authorization) { "Bearer #{outside_instructor_token}" }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('You are not authorized to index this course_reports')
        end
      end

      response '401', 'Unauthorized' do
        let(:course_id) { course.id }
        let(:Authorization) { 'Bearer invalid_token' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end

      response '401', 'Unauthorized without a bearer token' do
        let(:course_id) { course.id }
        let(:Authorization) { '' }

        run_test! do |response|
          expect(JSON.parse(response.body)['error']).to eq('Not Authorized')
        end
      end
    end
  end
end
