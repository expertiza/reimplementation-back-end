# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentTask, type: :model do
  let!(:student_role) { Role.find_or_create_by!(name: 'Student') }
  let!(:instructor_role) { Role.find_or_create_by!(name: 'Instructor') }
  let!(:institution) { Institution.create!(name: 'NC State') }
  let!(:instructor) do
    User.create!(
      name: 'modelinstructor',
      email: 'modelinstructor@example.com',
      password: 'password',
      full_name: 'Model Instructor',
      institution: institution,
      role: instructor_role
    )
  end
  let!(:student) do
    User.create!(
      name: 'modelstudent',
      email: 'modelstudent@example.com',
      password: 'password',
      full_name: 'Model Student',
      institution: institution,
      role: student_role
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
  let!(:assignment) do
    Assignment.create!(
      name: 'Program 1',
      instructor: instructor,
      course: course,
      has_topics: true
    )
  end
  let!(:team) { Team.create!(assignment: assignment) }
  let!(:topic) do
    SignUpTopic.create!(
      assignment: assignment,
      topic_identifier: 'P1',
      topic_name: 'Program Topic',
      max_choosers: 1
    )
  end
  let!(:signed_up_team) { SignedUpTeam.create!(team: team, sign_up_topic: topic) }
  let!(:assignment_due_date) do
    DueDate.create!(
      parent: assignment,
      due_at: Time.zone.parse('2026-04-02 12:00:00'),
      submission_allowed_id: 3,
      review_allowed_id: 3,
      deadline_type_id: 1,
      deadline_name: 'Submission deadline'
    )
  end
  let!(:topic_due_date) do
    DueDate.create!(
      parent: topic,
      due_at: Time.zone.parse('2026-04-03 12:00:00'),
      submission_allowed_id: 3,
      review_allowed_id: 3,
      deadline_type_id: 2,
      round: 1
    )
  end

  describe '.from_participant' do
    it 'builds a task from participant relationships and serializes deterministic data' do
      participant = Participant.create!(
        user: student,
        assignment: assignment,
        team: team,
        current_stage: 'Submitted',
        permission_granted: true,
        stage_deadline: Time.zone.parse('2026-04-04 10:00:00')
      )

      task = described_class.from_participant(participant)

      expect(task.assignment).to eq(assignment)
      expect(task.course).to eq(course)
      expect(task.team).to eq(team)
      expect(task.topic).to eq('P1')
      expect(task.current_stage).to eq('Submitted')
      expect(task.stage_deadline).to eq(Time.zone.parse('2026-04-04 10:00:00'))
      expect(task.permission_granted).to be(true)
      expect(task.deadlines.map(&:id)).to eq([assignment_due_date.id, topic_due_date.id])
      expect(task.review_grade).to be_nil

      expect(task.as_json).to include(
        id: participant.id,
        participant_id: participant.id,
        assignment_id: assignment.id,
        assignment: 'Program 1',
        course_id: course.id,
        course: 'CSC 517',
        team_id: team.id,
        team_name: "Team #{team.id}",
        topic: 'P1',
        current_stage: 'Submitted',
        permission_granted: true,
        review_grade: nil
      )
    end

    it 'falls back to due dates when the participant stage deadline is missing' do
      participant = Participant.create!(
        user: student,
        assignment: assignment,
        team: team,
        topic: 'Manual Topic',
        current_stage: nil,
        permission_granted: false,
        stage_deadline: nil
      )

      task = described_class.from_participant(participant)

      expect(task.topic).to eq('Manual Topic')
      expect(task.current_stage).to eq('Unknown')
      expect(task.stage_deadline).to eq(assignment_due_date.due_at)
    end
  end

  describe '.from_user' do
    it 'returns only the current user tasks sorted by stage deadline' do
      other_student = User.create!(
        name: 'othermodelstudent',
        email: 'othermodelstudent@example.com',
        password: 'password',
        full_name: 'Other Student',
        institution: institution,
        role: student_role
      )

      later_assignment = Assignment.create!(name: 'Program 2', instructor: instructor, course: course)
      later_team = Team.create!(assignment: later_assignment)

      earlier_participant = Participant.create!(
        user: student,
        assignment: assignment,
        team: team,
        stage_deadline: Time.zone.parse('2026-04-01 09:00:00'),
        current_stage: 'In progress'
      )
      later_participant = Participant.create!(
        user: student,
        assignment: later_assignment,
        team: later_team,
        stage_deadline: Time.zone.parse('2026-05-01 09:00:00'),
        current_stage: 'Not started'
      )
      Participant.create!(
        user: other_student,
        assignment: assignment,
        team: team,
        stage_deadline: Time.zone.parse('2026-03-01 09:00:00'),
        current_stage: 'Submitted'
      )

      tasks = described_class.from_user(student)

      expect(tasks.map { |task| task.participant.id }).to eq([earlier_participant.id, later_participant.id])
    end
  end

  describe '.from_participant_id' do
    it 'returns nil when the participant does not exist' do
      expect(described_class.from_participant_id(999_999)).to be_nil
    end
  end
end
