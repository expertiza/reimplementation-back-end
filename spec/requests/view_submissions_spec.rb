# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'GET /submitted_content/:id/view_submissions', type: :request do
  # ------------------------------------------------------------------
  # Shared test data
  # ------------------------------------------------------------------
  let(:institution) { Institution.create!(name: 'NC State University') }

  let(:instructor) do
    User.create!(
      name: 'instructor1',
      email: 'instructor@example.com',
      password: 'password',
      full_name: 'Test Instructor',
      institution_id: institution.id,
      role_id: Role.find_or_create_by!(name: 'Instructor').id
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'Test Assignment',
      instructor_id: instructor.id,
      has_teams: true,
      private: false
    )
  end

  let(:student_role) { Role.find_or_create_by!(name: 'Student') }

  let(:student1) do
    User.create!(
      name: 'student1',
      email: 'student1@example.com',
      password: 'password',
      full_name: 'Alice Smith',
      institution_id: institution.id,
      role_id: student_role.id
    )
  end

  let(:student2) do
    User.create!(
      name: 'student2',
      email: 'student2@example.com',
      password: 'password',
      full_name: 'Bob Jones',
      institution_id: institution.id,
      role_id: student_role.id
    )
  end

  let(:team) do
    AssignmentTeam.create!(name: 'Team Alpha', parent_id: assignment.id)
  end

  let!(:teams_user1) { TeamsUser.create!(team_id: team.id, user_id: student1.id) }
  let!(:teams_user2) { TeamsUser.create!(team_id: team.id, user_id: student2.id) }

  let(:auth_headers) do
    token = JsonWebToken.encode({ id: instructor.id })
    { 'Authorization' => "Bearer #{token}" }
  end

  # ------------------------------------------------------------------
  # Helper
  # ------------------------------------------------------------------
  def get_view_submissions(id, headers: auth_headers)
    get "/submitted_content/#{id}/view_submissions", headers: headers
  end

  # ==================================================================
  # 1. Assignment not found
  # ==================================================================
  describe 'when assignment does not exist' do
    it 'returns 404 with an error message' do
      get_view_submissions(999_999)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Assignment not found')
    end
  end

  # ==================================================================
  # 2. Assignment exists but has no teams
  # ==================================================================
  describe 'when assignment has no teams' do
    let(:empty_assignment) do
      Assignment.create!(
        name: 'Empty Assignment',
        instructor_id: instructor.id,
        has_teams: true,
        private: false
      )
    end

    it 'returns 200 with an empty submissions array' do
      get_view_submissions(empty_assignment.id)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['assignment_id']).to eq(empty_assignment.id)
      expect(body['submissions']).to eq([])
    end
  end

  # ==================================================================
  # 3. Assignment with teams but no submission records
  # ==================================================================
  describe 'when teams exist but have no submission records' do
    it 'returns 200 with teams listed but empty links and files' do
      get_view_submissions(assignment.id)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body

      expect(body['assignment_id']).to eq(assignment.id)
      expect(body['assignment_name']).to eq('Test Assignment')
      expect(body['submissions'].length).to eq(1)

      submission = body['submissions'].first
      expect(submission['team_name']).to eq('Team Alpha')
      expect(submission['links']).to eq([])
      expect(submission['files']).to eq([])
    end

    it 'includes all team members with correct fields' do
      get_view_submissions(assignment.id)

      members = response.parsed_body['submissions'].first['members']
      expect(members.length).to eq(2)

      emails = members.map { |m| m['email'] }
      expect(emails).to contain_exactly(student1.email, student2.email)

      full_names = members.map { |m| m['full_name'] }
      expect(full_names).to contain_exactly(student1.full_name, student2.full_name)
    end
  end

  # ==================================================================
  # 4. Team with hyperlink submission records
  # ==================================================================
  describe 'when team has hyperlink submission records' do
    let!(:hyperlink_record) do
      SubmissionRecord.create!(
        record_type: 'hyperlink',
        content: 'https://github.com/student1/project',
        operation: 'Submit Hyperlink',
        team_id: team.id,
        user: student1.name,
        assignment_id: assignment.id
      )
    end

    it 'returns the hyperlink in the links array' do
      get_view_submissions(assignment.id)

      expect(response).to have_http_status(:ok)
      links = response.parsed_body['submissions'].first['links']
      expect(links.length).to eq(1)
      expect(links.first['url']).to eq('https://github.com/student1/project')
      expect(links.first['type']).to eq('Hyperlink')
    end

    it 'does not include hyperlinks in the files array' do
      get_view_submissions(assignment.id)

      files = response.parsed_body['submissions'].first['files']
      expect(files).to eq([])
    end

    it 'returns multiple hyperlinks when several exist' do
      SubmissionRecord.create!(
        record_type: 'hyperlink',
        content: 'https://youtu.be/demo-video',
        operation: 'Submit Hyperlink',
        team_id: team.id,
        user: student2.name,
        assignment_id: assignment.id
      )

      get_view_submissions(assignment.id)

      links = response.parsed_body['submissions'].first['links']
      expect(links.length).to eq(2)
      urls = links.map { |l| l['url'] }
      expect(urls).to contain_exactly(
        'https://github.com/student1/project',
        'https://youtu.be/demo-video'
      )
    end
  end

  # ==================================================================
  # 5. Team with file submission records
  # ==================================================================
  describe 'when team has file submission records' do
    let!(:file_record) do
      SubmissionRecord.create!(
        record_type: 'file',
        content: 'https://example.com/uploads/report.pdf',
        operation: 'Submit File',
        team_id: team.id,
        user: student1.name,
        assignment_id: assignment.id
      )
    end

    it 'returns the file in the files array' do
      get_view_submissions(assignment.id)

      expect(response).to have_http_status(:ok)
      files = response.parsed_body['submissions'].first['files']
      expect(files.length).to eq(1)
      expect(files.first['name']).to eq('report.pdf')
      expect(files.first['url']).to eq('https://example.com/uploads/report.pdf')
    end

    it 'correctly extracts file extension as type' do
      get_view_submissions(assignment.id)

      files = response.parsed_body['submissions'].first['files']
      expect(files.first['type']).to eq('PDF')
    end

    it 'does not include files in the links array' do
      get_view_submissions(assignment.id)

      links = response.parsed_body['submissions'].first['links']
      expect(links).to eq([])
    end
  end

  # ==================================================================
  # 6. Team with both hyperlinks and files
  # ==================================================================
  describe 'when team has both hyperlinks and files' do
    before do
      SubmissionRecord.create!(
        record_type: 'hyperlink',
        content: 'https://github.com/team/repo',
        operation: 'Submit Hyperlink',
        team_id: team.id,
        user: student1.name,
        assignment_id: assignment.id
      )
      SubmissionRecord.create!(
        record_type: 'file',
        content: 'https://example.com/slides.pptx',
        operation: 'Submit File',
        team_id: team.id,
        user: student2.name,
        assignment_id: assignment.id
      )
    end

    it 'returns links and files in separate arrays' do
      get_view_submissions(assignment.id)

      submission = response.parsed_body['submissions'].first
      expect(submission['links'].length).to eq(1)
      expect(submission['files'].length).to eq(1)
      expect(submission['links'].first['type']).to eq('Hyperlink')
      expect(submission['files'].first['type']).to eq('PPTX')
    end
  end

  # ==================================================================
  # 7. Submission records from another assignment are not included
  # ==================================================================
  describe 'when submission records exist for a different assignment' do
    let(:other_assignment) do
      Assignment.create!(
        name: 'Other Assignment',
        instructor_id: instructor.id,
        has_teams: true,
        private: false
      )
    end

    before do
      SubmissionRecord.create!(
        record_type: 'hyperlink',
        content: 'https://github.com/other/repo',
        operation: 'Submit Hyperlink',
        team_id: team.id,
        user: student1.name,
        assignment_id: other_assignment.id  # different assignment
      )
    end

    it 'does not include records from other assignments' do
      get_view_submissions(assignment.id)

      links = response.parsed_body['submissions'].first['links']
      expect(links).to eq([])
    end
  end

  # ==================================================================
  # 8. Multiple teams
  # ==================================================================
  describe 'when the assignment has multiple teams' do
    let(:team2) { AssignmentTeam.create!(name: 'Team Beta', parent_id: assignment.id) }
    let(:student3) do
      User.create!(
        name: 'student3',
        email: 'student3@example.com',
        password: 'password',
        full_name: 'Carol White',
        institution_id: institution.id,
        role_id: student_role.id
      )
    end

    before do
      TeamsUser.create!(team_id: team2.id, user_id: student3.id)
      SubmissionRecord.create!(
        record_type: 'hyperlink',
        content: 'https://github.com/team2/repo',
        operation: 'Submit Hyperlink',
        team_id: team2.id,
        user: student3.name,
        assignment_id: assignment.id
      )
    end

    it 'returns a submission entry for each team' do
      get_view_submissions(assignment.id)

      submissions = response.parsed_body['submissions']
      expect(submissions.length).to eq(2)
      team_names = submissions.map { |s| s['team_name'] }
      expect(team_names).to contain_exactly('Team Alpha', 'Team Beta')
    end

    it 'only includes each team\'s own records' do
      get_view_submissions(assignment.id)

      submissions = response.parsed_body['submissions']
      alpha = submissions.find { |s| s['team_name'] == 'Team Alpha' }
      beta  = submissions.find { |s| s['team_name'] == 'Team Beta' }

      expect(alpha['links']).to eq([])
      expect(beta['links'].first['url']).to eq('https://github.com/team2/repo')
    end
  end

  # ==================================================================
  # 9. Team with no members
  # ==================================================================
  describe 'when a team has no members' do
    let!(:empty_team) { AssignmentTeam.create!(name: 'Empty Team', parent_id: assignment.id) }

    it 'returns the team with an empty members array' do
      get "/submitted_content/#{assignment.id}/view_submissions", headers: auth_headers

      submission = response.parsed_body['submissions'].find { |s| s['team_name'] == 'Empty Team' }
      expect(submission).not_to be_nil
      expect(submission['members']).to eq([])
    end
  end

  # ==================================================================
  # 10. Response shape contract
  # ==================================================================
  describe 'response shape' do
    it 'always includes required top-level keys' do
      get_view_submissions(assignment.id)

      body = response.parsed_body
      expect(body.keys).to include('assignment_id', 'assignment_name', 'submissions')
    end

    it 'each submission always includes required keys' do
      get_view_submissions(assignment.id)

      submission = response.parsed_body['submissions'].first
      expect(submission.keys).to include('id', 'team_id', 'team_name', 'members', 'links', 'files')
    end

    it 'each member always includes required keys' do
      get_view_submissions(assignment.id)

      member = response.parsed_body['submissions'].first['members'].first
      expect(member.keys).to include('full_name', 'email', 'github')
    end
  end
end