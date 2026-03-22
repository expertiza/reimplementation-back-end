# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentTask, type: :model do
  describe '.from_participant' do
    let(:course) { instance_double(Course, id: 3, name: 'CSC 517') }
    let(:assignment) { instance_double(Assignment, id: 5, name: 'Final Project', course: course) }
    let(:team) do
      instance_double(
        AssignmentTeam,
        id: 7,
        name: 'Team Alpha',
        aggregate_review_grade: nil,
        grade_for_submission: 92,
        comment_for_submission: 'Please revise the intro.'
      )
    end
    let(:project_topic) { instance_double(ProjectTopic, id: 11, topic_identifier: 'E2442', topic_name: 'Topic E2442') }
    let(:participant_user) { instance_double(User, id: 13, name: 'studenta', full_name: 'Student A') }
    let(:participant) do
      instance_double(
        AssignmentParticipant,
        id: 17,
        assignment: assignment,
        assignment_id: assignment.id,
        topic: nil,
        current_stage: 'Review',
        stage_deadline: '2026-04-23 12:00:00 UTC',
        permission_granted: true
      )
    end
    let(:deadline) do
      instance_double(
        DueDate,
        id: 19,
        deadline_name: 'Submission deadline',
        due_at: Time.zone.parse('2026-04-25 12:00:00 UTC'),
        deadline_type_id: 1,
        resubmission_allowed_id: 3,
        round: nil,
        parent_type: 'Assignment',
        parent_id: assignment.id
      )
    end
    let(:feedback) do
      [{
        response_id: 23,
        reviewer_name: 'Reviewer One',
        comment: 'Looks good.',
        submitted_at: '2026-04-22T10:00:00Z'
      }]
    end
    let(:revision_request) do
      instance_double(
        RevisionRequest,
        status: 'PENDING',
        as_json: { id: 29, status: 'PENDING', comments: 'Please revise the intro.' }
      )
    end
    let(:team_members) do
      [{ id: 13, name: 'studenta', full_name: 'Student A' }]
    end

    before do
      allow(StudentTask).to receive(:resolve_team).with(participant).and_return(team)
      allow(StudentTask).to receive(:resolve_project_topic).with(participant, team).and_return(project_topic)
      allow(StudentTask).to receive(:resolve_deadlines).with(assignment, project_topic).and_return([deadline])
      allow(StudentTask).to receive(:resolve_latest_revision_request).with(participant, team).and_return(revision_request)
      allow(StudentTask).to receive(:resolve_review_grade).with(team).and_return(nil)
      allow(StudentTask).to receive(:resolve_team_members).with(team).and_return(team_members)
      allow(StudentTask).to receive(:build_timeline).with([deadline], 'Review').and_return([{ label: 'Submission deadline', phase: 'submission' }])
      allow(StudentTask).to receive(:resolve_feedback).with(team, assignment).and_return(feedback)
    end

    it 'builds a composed student task payload from an assignment participant' do
      task = described_class.from_participant(participant)

      expect(task.assignment).to eq(assignment)
      expect(task.course).to eq(course)
      expect(task.team).to eq(team)
      expect(task.project_topic).to eq(project_topic)
      expect(task.topic).to eq('E2442')
      expect(task.current_stage).to eq('Review')
      expect(task.stage_deadline).to eq(Time.zone.parse('2026-04-23 12:00:00 UTC'))
      expect(task.permission_granted).to be(true)
      expect(task.deadlines).to eq([deadline])
      expect(task.timeline).to eq([{ label: 'Submission deadline', phase: 'submission' }])
      expect(task.feedback).to eq(feedback)
      expect(task.submission_feedback).to eq(
        grade_for_submission: 92,
        comment_for_submission: 'Please revise the intro.'
      )
      expect(task.can_request_revision).to be(false)
      expect(task.revision_request).to eq(revision_request)
    end

    it 'serializes the composed payload into frontend-friendly JSON' do
      task = described_class.from_participant(participant)
      json = task.as_json

      expect(json).to include(
        participant_id: 17,
        assignment_id: 5,
        assignment: 'Final Project',
        course_id: 3,
        course: 'CSC 517',
        team_id: 7,
        team_name: 'Team Alpha',
        topic: 'E2442',
        current_stage: 'Review',
        permission_granted: true,
        can_request_revision: false,
        review_grade: nil
      )
      expect(json[:topic_details]).to include(id: 11, identifier: 'E2442', name: 'Topic E2442')
      expect(json[:assignment_details]).to include(id: 5, name: 'Final Project', course_id: 3, course_name: 'CSC 517')
      expect(json[:team_details]).to include(id: 7, name: 'Team Alpha')
      expect(json[:feedback]).to eq(feedback)
      expect(json[:submission_feedback]).to eq(
        grade_for_submission: 92,
        comment_for_submission: 'Please revise the intro.'
      )
      expect(json[:revision_request]).to eq(id: 29, status: 'PENDING', comments: 'Please revise the intro.')
    end
  end

  describe '.from_participant_id' do
    it 'returns nil when the participant cannot be found' do
      allow(AssignmentParticipant).to receive(:find_by).with(id: 999).and_return(nil)

      expect(described_class.from_participant_id(999)).to be_nil
    end

    it 'looks up assignment participants and delegates task construction' do
      participant = instance_double(AssignmentParticipant)

      allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(participant)
      allow(described_class).to receive(:from_participant).with(participant).and_return(:task)

      expect(described_class.from_participant_id(1)).to eq(:task)
    end
  end

  describe '.parse_deadline' do
    it 'parses valid deadline strings' do
      expect(described_class.send(:parse_deadline, '2026-04-25 12:00:00 UTC')).to eq(Time.zone.parse('2026-04-25 12:00:00 UTC'))
    end

    it 'returns nil for invalid deadline input' do
      expect(described_class.send(:parse_deadline, 'not-a-date')).to be_nil
    end
  end

  describe '.can_request_revision?' do
    it 'returns true when resubmission is allowed and there is no pending request' do
      deadline = instance_double(DueDate, resubmission_allowed_id: 3, due_at: 1.day.from_now)
      team = instance_double(AssignmentTeam)

      expect(described_class.send(:can_request_revision?, team, [deadline], nil)).to be(true)
    end

    it 'returns false when a pending revision request already exists' do
      deadline = instance_double(DueDate, resubmission_allowed_id: 3, due_at: 1.day.from_now)
      team = instance_double(AssignmentTeam)
      request = instance_double(RevisionRequest, status: RevisionRequest::PENDING)

      expect(described_class.send(:can_request_revision?, team, [deadline], request)).to be(false)
    end

    it 'returns false when the latest revision request has already been approved' do
      deadline = instance_double(DueDate, resubmission_allowed_id: 3, due_at: 1.day.from_now)
      team = instance_double(AssignmentTeam)
      request = instance_double(RevisionRequest, status: RevisionRequest::APPROVED)

      expect(described_class.send(:can_request_revision?, team, [deadline], request)).to be(false)
    end

    it 'returns false when there is no team submission for the task' do
      deadline = instance_double(DueDate, resubmission_allowed_id: 3, due_at: 1.day.from_now)

      expect(described_class.send(:can_request_revision?, nil, [deadline], nil)).to be(false)
    end
  end
end
