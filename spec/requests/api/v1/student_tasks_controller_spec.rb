# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks API', type: :request do
  include RolesHelper

  let!(:roles) { create_roles_hierarchy }
  let!(:institution) { Institution.create!(name: 'NC State') }

  let!(:instructor) do
    User.create!(
      name: 'instructor1',
      email: 'instructor1@example.com',
      password: 'password',
      full_name: 'Instructor One',
      institution: institution,
      role: roles[:instructor]
    )
  end

  let!(:course) do
    Course.create!(
      name: 'CSC 517',
      directory_path: 'csc517',
      institution: institution,
      instructor: instructor
    )
  end

  let!(:student) do
    User.create!(
      name: 'student1',
      email: 'student1@example.com',
      password: 'password',
      full_name: 'Student One',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:other_student) do
    User.create!(
      name: 'student2',
      email: 'student2@example.com',
      password: 'password',
      full_name: 'Student Two',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:empty_student) do
    User.create!(
      name: 'student3',
      email: 'student3@example.com',
      password: 'password',
      full_name: 'Student Three',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:assignment_one) do
    Assignment.create!(
      name: 'Assignment One',
      instructor: instructor,
      course: course,
      directory_path: 'assignment_one',
      has_topics: true
    )
  end

  let!(:assignment_two) do
    Assignment.create!(
      name: 'Assignment Two',
      instructor: instructor,
      course: course,
      directory_path: 'assignment_two'
    )
  end

  let!(:team_one) do
    AssignmentTeam.create!(
      name: 'Team Alpha',
      parent_id: assignment_one.id,
      grade_for_submission: 88,
      comment_for_submission: 'Please revise section 2.'
    )
  end

  let!(:team_two) do
    AssignmentTeam.create!(
      name: 'Team Beta',
      parent_id: assignment_two.id
    )
  end

  let!(:project_topic) do
    ProjectTopic.create!(
      assignment: assignment_one,
      topic_identifier: 'T1',
      topic_name: 'Distributed Scheduler',
      max_choosers: 2,
      category: 'General'
    )
  end

  let!(:signed_up_team) do
    SignedUpTeam.create!(
      team: team_one,
      project_topic: project_topic,
      is_waitlisted: false
    )
  end

  let!(:assignment_deadline) do
    DueDate.create!(
      parent: assignment_one,
      due_at: Time.zone.parse('2026-04-01 12:00:00'),
      submission_allowed_id: 3,
      resubmission_allowed_id: 3,
      review_allowed_id: 3,
      deadline_type_id: 1,
      deadline_name: 'Submission deadline'
    )
  end

  let!(:topic_deadline) do
    DueDate.create!(
      parent: project_topic,
      due_at: Time.zone.parse('2026-04-05 12:00:00'),
      submission_allowed_id: 3,
      review_allowed_id: 3,
      deadline_type_id: 2,
      deadline_name: 'Topic review deadline',
      round: 1
    )
  end

  let!(:assignment_two_deadline) do
    DueDate.create!(
      parent: assignment_two,
      due_at: Time.zone.parse('2026-05-01 12:00:00'),
      submission_allowed_id: 3,
      review_allowed_id: 3,
      deadline_type_id: 1,
      deadline_name: 'Assignment two submission deadline'
    )
  end

  let!(:student_task_participant) do
    AssignmentParticipant.create!(
      user: student,
      assignment: assignment_one,
      handle: student.name,
      permission_granted: true,
      topic: nil,
      current_stage: 'In progress',
      stage_deadline: Time.zone.parse('2026-04-03 09:00:00')
    )
  end

  let!(:second_student_task_participant) do
    AssignmentParticipant.create!(
      user: student,
      assignment: assignment_two,
      handle: student.name,
      permission_granted: false,
      topic: 'Fallback Topic',
      current_stage: 'Not started',
      stage_deadline: Time.zone.parse('2026-05-02 09:00:00')
    )
  end

  let!(:other_student_participant) do
    AssignmentParticipant.create!(
      user: other_student,
      assignment: assignment_one,
      handle: other_student.name,
      permission_granted: false,
      topic: 'Private Topic',
      current_stage: 'Submitted',
      stage_deadline: Time.zone.parse('2026-04-10 09:00:00')
    )
  end

  let!(:student_team_membership) do
    TeamsParticipant.create!(team: team_one, participant: student_task_participant, user: student)
  end

  let!(:other_student_team_membership) do
    TeamsParticipant.create!(team: team_one, participant: other_student_participant, user: other_student)
  end

  let!(:second_student_team_membership) do
    TeamsParticipant.create!(team: team_two, participant: second_student_task_participant, user: student)
  end

  let!(:review_response_map) do
    ReviewResponseMap.create!(
      reviewed_object_id: assignment_one.id,
      reviewer_id: other_student_participant.id,
      reviewee_id: team_one.id
    )
  end

  let!(:review_response) do
    Response.create!(
      map_id: review_response_map.id,
      additional_comment: 'Strong work overall.',
      is_submitted: true
    )
  end

  let(:headers) { auth_headers_for(student) }
  let(:empty_headers) { auth_headers_for(empty_student) }

  describe 'GET /student_tasks/list' do
    it 'returns the current student task list with consistent task data' do
      get '/student_tasks/list', headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body.map { |task| task['participant_id'] }).to eq([student_task_participant.id, second_student_task_participant.id])
      expect(body.map { |task| task['assignment'] }).to eq(['Assignment One', 'Assignment Two'])

      first_task = body.first
      expect(first_task).to include(
        'participant_id' => student_task_participant.id,
        'assignment_id' => assignment_one.id,
        'assignment' => 'Assignment One',
        'course_id' => course.id,
        'course' => 'CSC 517',
        'team_id' => team_one.id,
        'team_name' => 'Team Alpha',
        'topic' => 'T1',
        'current_stage' => 'In progress',
        'permission_granted' => true,
        'can_request_revision' => true,
        'review_grade' => nil
      )
      expect(first_task['submission_feedback']).to include(
        'grade_for_submission' => 88,
        'comment_for_submission' => 'Please revise section 2.'
      )
      expect(first_task['team_members']).to contain_exactly(
        a_hash_including('id' => student.id, 'name' => 'student1', 'full_name' => 'Student One'),
        a_hash_including('id' => other_student.id, 'name' => 'student2', 'full_name' => 'Student Two')
      )
      expect(first_task['stage_deadline']).to eq('2026-04-03T09:00:00Z')
      expect(first_task['deadlines']).to contain_exactly(
        a_hash_including(
          'id' => assignment_deadline.id,
          'name' => 'Submission deadline',
          'deadline_type_id' => 1,
          'parent_type' => 'Assignment',
          'parent_id' => assignment_one.id
        ),
        a_hash_including(
          'id' => topic_deadline.id,
          'name' => 'Topic review deadline',
          'deadline_type_id' => 2,
          'round' => 1,
          'parent_type' => 'ProjectTopic',
          'parent_id' => project_topic.id
        )
      )
      expect(first_task['topic_details']).to include(
        'id' => project_topic.id,
        'identifier' => 'T1',
        'name' => 'Distributed Scheduler'
      )
      expect(first_task['team_details']).to include(
        'id' => team_one.id,
        'name' => 'Team Alpha'
      )
      expect(first_task['assignment_details']).to include(
        'id' => assignment_one.id,
        'name' => 'Assignment One',
        'course_id' => course.id,
        'course_name' => 'CSC 517'
      )
      expect(first_task['timeline']).to include(
        a_hash_including('label' => 'Submission deadline', 'phase' => 'submission'),
        a_hash_including('label' => 'Topic review deadline', 'phase' => 'review')
      )
      expect(first_task['feedback']).to include(
        a_hash_including(
          'response_id' => review_response.id,
          'reviewer_name' => 'Student Two',
          'comment' => 'Strong work overall.'
        )
      )
    end

    it 'returns an empty array when the student has no tasks' do
      get '/student_tasks/list', headers: empty_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'returns unauthorized without a valid token' do
      get '/student_tasks/list'

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  describe 'GET /student_tasks/:id' do
    it 'returns the requested student task for the owner' do
      get "/student_tasks/#{student_task_participant.id}", headers: headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body['participant_id']).to eq(student_task_participant.id)
      expect(body['assignment']).to eq('Assignment One')
      expect(body['topic']).to eq('T1')
      expect(body['can_request_revision']).to be(true)
      expect(body['submission_feedback']).to include(
        'grade_for_submission' => 88,
        'comment_for_submission' => 'Please revise section 2.'
      )
      expect(body['deadlines'].size).to eq(2)
      expect(body['feedback']).to include(
        a_hash_including(
          'response_id' => review_response.id,
          'reviewer_name' => 'Student Two',
          'comment' => 'Strong work overall.'
        )
      )
      expect(body['timeline']).to include(
        a_hash_including('label' => 'Submission deadline', 'phase' => 'submission'),
        a_hash_including('label' => 'Topic review deadline', 'phase' => 'review')
      )
    end

    it 'returns forbidden for another student task' do
      get "/student_tasks/#{other_student_participant.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq('error' => 'You are not authorized to access this student task')
    end

    it 'returns not found for an invalid task id' do
      get '/student_tasks/999999', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'Student task not found')
    end

    it 'returns unauthorized without a valid token' do
      get "/student_tasks/#{student_task_participant.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  describe 'GET /student_tasks/view' do
    it 'supports the legacy detail endpoint with the same task payload' do
      get '/student_tasks/view', params: { id: student_task_participant.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'participant_id' => student_task_participant.id,
        'assignment' => 'Assignment One'
      )
    end
  end

  describe 'POST /student_tasks/:id/request_revision' do
    it 'creates a revision request for the student task owner' do
      post "/student_tasks/#{student_task_participant.id}/request_revision",
           params: { comments: 'Please allow me to revise the submission based on the feedback.' },
           headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)

      expect(body['message']).to eq('Revision request submitted successfully')
      expect(body['revision_request']).to include(
        'participant_id' => student_task_participant.id,
        'team_id' => team_one.id,
        'assignment_id' => assignment_one.id,
        'status' => 'PENDING',
        'comments' => 'Please allow me to revise the submission based on the feedback.'
      )
      expect(body['student_task']['can_request_revision']).to be(false)
      expect(body['student_task']['revision_request']).to include(
        'status' => 'PENDING',
        'comments' => 'Please allow me to revise the submission based on the feedback.'
      )
    end

    it 'rejects duplicate pending revision requests for the same task' do
      RevisionRequest.create!(
        participant: student_task_participant,
        team: team_one,
        assignment: assignment_one,
        comments: 'Existing revision request'
      )

      post "/student_tasks/#{student_task_participant.id}/request_revision",
           params: { comments: 'Another revision request' },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Revision requests are not available for this task')
    end

    it 'rejects revision requests when resubmission is not available for the task' do
      post "/student_tasks/#{second_student_task_participant.id}/request_revision",
           params: { comments: 'Please reopen this submission' },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Revision requests are not available for this task')
    end

    it 'returns forbidden when the task belongs to another student' do
      post "/student_tasks/#{other_student_participant.id}/request_revision",
           params: { comments: 'Please reopen this submission' },
           headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)).to eq('error' => 'You are not authorized to access this student task')
    end

    it 'returns not found for an invalid task id' do
      post '/student_tasks/999999/request_revision',
           params: { comments: 'Please reopen this submission' },
           headers: headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'Student task not found')
    end

    it 'returns unauthorized without a valid token' do
      post "/student_tasks/#{student_task_participant.id}/request_revision",
           params: { comments: 'Please reopen this submission' }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode(id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end
