# frozen_string_literal: true

require 'rails_helper'


RSpec.describe StudentTask, type: :model do
  before(:each) do
    @course     = double(name: "CSC 517")
    @assignment = double(name: "Final Project", course: @course, id: 1)
    @team       = double(id: 1, hyperlinks: [], has_submissions?: false)
    @user       = double(id: 1, try: nil)
    @participant = double(
      assignment: @assignment,
      topic:             "E2442",
      current_stage:     "submission",
      stage_deadline:    "2024-04-23",
      permission_granted: true,
      team:              @team,
      user:              @user,
      id:                1
    )
    allow(DueDate).to receive(:current_stage_for).with(@assignment).and_return("submission")
    allow(DueDate).to receive(:next_due_date).with(@assignment).and_return(nil)
    allow(SignedUpTeam).to receive(:find_by).and_return(nil)
    allow(ReviewResponseMap).to receive(:where).and_return([])
    allow(FeedbackResponseMap).to receive(:where).and_return([])
  end

  describe ".initialize" do
    it "correctly assigns all attributes" do
      args = {
        assignment:         @assignment,
        course:             "CSC 517",
        current_stage:      "submission",
        participant:        @participant,
        stage_deadline:     "2024-04-23",
        topic:              "E2442",
        permission_granted: false
      }

      student_task = StudentTask.new(args)

      expect(student_task.assignment.name).to eq("Final Project")
      expect(student_task.course).to eq("CSC 517")
      expect(student_task.current_stage).to eq("submission")
      expect(student_task.participant).to eq(@participant)
      expect(student_task.stage_deadline).to eq("2024-04-23")
      expect(student_task.topic).to eq("E2442")
    end
  end

  describe ".from_participant" do
    it "creates an instance from a participant instance" do
      student_task = StudentTask.create_from_participant(@participant)

      expect(student_task.assignment).to eq(@assignment.name)
      expect(student_task.course).to eq(@course.name)
      expect(student_task.topic).to be_nil # SignedUpTeam stubbed to return nil
      expect(student_task.current_stage).to eq("submission")
      expect(student_task.permission_granted).to be @participant.permission_granted
      expect(student_task.participant).to be @participant
    end
  end

  describe ".parse_stage_deadline" do
    context "valid date string" do
      it "parses the date string into a Time object" do
        valid_date = "2024-04-25"
        expect(StudentTask.send(:parse_stage_deadline, valid_date)).to eq(Time.parse("2024-04-25"))
      end
    end

    context "invalid date string" do
      it "returns current time plus one year" do
        invalid_date = "invalid input"
        # Set the now to be 2024-05-01 for testing purpose
        allow(Time).to receive(:now).and_return(Time.new(2024, 5, 1))
        expected_time = Time.new(2025, 5, 1)
        expect(StudentTask.send(:parse_stage_deadline, invalid_date)).to eq(expected_time)
      end
    end
  end

  describe ".from_participant_id" do
    # Shared helper: builds a relation double that responds to the
    # .where(id:).includes(assignment: :course).includes(:user).first chain
    # used by from_participant_id, and returns the given participant from .first.
    def stub_participant_chain(participant)
      relation = double('relation')
      allow(AssignmentParticipant).to receive(:where).with(id: 1).and_return(relation)
      allow(relation).to receive(:includes).with(assignment: :course).and_return(relation)
      allow(relation).to receive(:includes).with(:user).and_return(relation)
      allow(relation).to receive(:first).and_return(participant)
      relation
    end

    it "uses AssignmentParticipant (not Participant) to look up by id" do
      # from_participant_id must scope to AssignmentParticipant so that other Participant
      # subclasses (e.g. CourseParticipant) for the same id cannot slip through and
      # cause type-mismatch 500s later in create_from_participant.
      relation = stub_participant_chain(@participant)
      expect(AssignmentParticipant).to receive(:where).with(id: 1).and_return(relation)
      expect(StudentTask).to receive(:create_from_participant).with(@participant)

      StudentTask.from_participant_id(1)
    end

    it "does not call the base Participant class for the lookup" do
      stub_participant_chain(@participant)
      allow(StudentTask).to receive(:create_from_participant)

      expect(Participant).not_to receive(:find_by)

      StudentTask.from_participant_id(1)
    end
  end

  describe ".tasks" do
    it "sorts by a single composite key [course, assignment, stage_deadline]" do
      # Three chained sort_by calls were non-deterministic (each overwrote the previous).
      # The fix uses one sort_by { [course, assignment, stage_deadline] }.
      course_a = double(name: "AAA Course")
      course_b = double(name: "BBB Course")

      assignment_a1 = double(name: "Alpha", course: course_a, id: 10)
      assignment_a2 = double(name: "Beta",  course: course_a, id: 11)
      assignment_b1 = double(name: "Alpha", course: course_b, id: 12)

      deadline_near = Time.parse("2025-01-01")
      deadline_far  = Time.parse("2025-06-01")

      # Participants stub — course_a/Beta should sort before course_a/Alpha because of
      # alphabetical assignment name comparison within the same course
      p1 = double(assignment: assignment_a2, team: @team, user: @user, permission_granted: true, id: 1)
      p2 = double(assignment: assignment_a1, team: @team, user: @user, permission_granted: true, id: 2)
      p3 = double(assignment: assignment_b1, team: @team, user: @user, permission_granted: true, id: 3)

      user = double(id: 42)
      allow(DueDate).to receive(:current_stage_for).and_return("submission")
      allow(DueDate).to receive(:next_due_date).and_return(nil)
      allow(SignedUpTeam).to receive(:find_by).and_return(nil)
      # tasks chains .includes(...) on the where result, so we need a relation
      # double that responds to both includes calls and delegates map to the array.
      relation = double('relation')
      allow(AssignmentParticipant).to receive(:where).with(user_id: user.id).and_return(relation)
      allow(relation).to receive(:includes).with(assignment: :course).and_return(relation)
      allow(relation).to receive(:includes).with(:user).and_return(relation)
      allow(relation).to receive(:map) { |&blk| [p3, p1, p2].map(&blk) }

      tasks = StudentTask.tasks(user)

      courses   = tasks.map(&:course)
      expect(courses).to eq(courses.sort), "tasks should be sorted by course first"

      same_course_tasks = tasks.select { |t| t.course == "AAA Course" }
      assignments = same_course_tasks.map(&:assignment)
      expect(assignments).to eq(assignments.sort), "tasks within same course should be sorted by assignment name"
    end
  end

  describe "#submission_updated?" do
    let(:participant) { double('participant', id: 1) }
    let(:task) { StudentTask.new(participant: participant, current_stage: 'submission') }

    context "when current stage is submission and team has hyperlinks" do
      it "returns true" do
        team = double('team', hyperlinks: ['http://example.com'], has_submissions?: false)
        allow(participant).to receive(:team).and_return(team)
        expect(task.send(:submission_updated?)).to be true
      end
    end

    context "when current stage is submission and team has no submissions" do
      it "returns false" do
        team = double('team', hyperlinks: [], has_submissions?: false)
        allow(participant).to receive(:team).and_return(team)
        expect(task.send(:submission_updated?)).to be false
      end
    end

    context "when current stage is review and submitted review exists" do
      it "returns true" do
        task_review = StudentTask.new(participant: participant, current_stage: 'review')
        allow(ReviewResponseMap).to receive(:where).and_return(
          double(joins: double(where: double(exists?: true)))
        )
        expect(task_review.send(:submission_updated?)).to be true
      end
    end

    context "when current stage is review and no submitted review exists" do
      it "returns false" do
        task_review = StudentTask.new(participant: participant, current_stage: 'review')
        allow(ReviewResponseMap).to receive(:where).and_return(
          double(joins: double(where: double(exists?: false)))
        )
        expect(task_review.send(:submission_updated?)).to be false
      end
    end
  end

  describe "#started?" do
    let(:participant) { double('participant', id: 1) }

    context "when in work stage and no work done" do
      it "returns false for submission stage with no submissions" do
        task = StudentTask.new(participant: participant, current_stage: 'submission')
        team = double('team', hyperlinks: [], has_submissions?: false)
        allow(participant).to receive(:team).and_return(team)
        expect(task.started?).to be false
      end

      it "returns false for review stage with no reviews given" do
        task = StudentTask.new(participant: participant, current_stage: 'review')
        allow(ReviewResponseMap).to receive(:where).and_return(
          double(joins: double(where: double(exists?: false)))
        )
        expect(task.started?).to be false
      end
    end

    context "when in work stage and work has been done" do
      it "returns true when submission has been made" do
        task = StudentTask.new(participant: participant, current_stage: 'submission')
        team = double('team', hyperlinks: ['http://example.com'], has_submissions?: false)
        allow(participant).to receive(:team).and_return(team)
        expect(task.started?).to be true
      end
    end

    context "when not in a work stage" do
      it "returns false for Finished stage" do
        task = StudentTask.new(participant: participant, current_stage: 'Finished')
        expect(task.started?).to be false
      end

      it "returns false for signup stage" do
        task = StudentTask.new(participant: participant, current_stage: 'signup')
        expect(task.started?).to be false
      end
    end
  end

end