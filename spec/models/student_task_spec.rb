# frozen_string_literal: true

require 'rails_helper'


RSpec.describe StudentTask, type: :model do
  before(:each) do
    @assignment = double(name: "Final Project", id: 101)
    @participant = double(
      assignment: @assignment,
      assignment_id: 101,
      id: 55,
      topic: "E2442",
      current_stage: "finished",
      stage_deadline: "2024-04-23",
      permission_granted: true
    )

  end

  describe ".initialize" do
    it "correctly assigns all attributes" do
      args = {
        assignment: @assignment,
        current_stage: "finished",
        participant: @participant,
        stage_deadline: "2024-04-23",
        topic: "E2442",
        permission_granted: false
      }

      student_task = StudentTask.new(args)

      expect(student_task.assignment.name).to eq("Final Project")
      expect(student_task.current_stage).to eq("finished")
      expect(student_task.participant).to eq(@participant)
      expect(student_task.stage_deadline).to eq("2024-04-23")
      expect(student_task.topic).to eq("E2442")
      expect(student_task.permission_granted).to be false
    end
  end

  describe ".from_participant" do
    it "creates an instance from a participant instance" do

      student_task = StudentTask.create_from_participant(@participant)

      expect(student_task.assignment).to eq("Final Project")
      expect(student_task.assignment_id).to eq(101)
      expect(student_task.participant_id).to eq(55)
      expect(student_task.topic).to eq(@participant.topic)
      expect(student_task.current_stage).to eq(@participant.current_stage)
      expect(student_task.stage_deadline).to eq(Time.parse(@participant.stage_deadline))
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
    it "fetches a participant by id and creates a student task from it" do
      allow(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(@participant)

      expect(AssignmentParticipant).to receive(:find_by).with(id: 1).and_return(@participant)
      expect(StudentTask).to receive(:create_from_participant).with(@participant)

      StudentTask.from_participant_id(1)
    end
  end

  describe '.from_user calibrated visibility' do
    let(:student) { create(:user, :student) }
    let(:instructor) { create(:user, :instructor) }
    let(:assignment) { create(:assignment, instructor: instructor, is_calibrated: true) }
    let!(:student_participant) do
      create(:assignment_participant, user: student, assignment: assignment, parent_id: assignment.id, handle: student.name)
    end
    let!(:instructor_participant) do
      create(:assignment_participant, user: instructor, assignment: assignment, parent_id: assignment.id, handle: instructor.name)
    end

    it 'hides calibrated assignment until a calibration response map exists' do
      expect(StudentTask.from_user(student)).to be_empty
    end

    it 'shows calibrated assignment after instructor adds calibration participant (map exists)' do
      ResponseMap.create!(
        reviewed_object_id: assignment.id,
        reviewer_id: instructor_participant.id,
        reviewee_id: student_participant.id,
        for_calibration: true
      )
      tasks = StudentTask.from_user(student)
      expect(tasks.size).to eq(1)
      expect(tasks.first.assignment_id).to eq(assignment.id)
    end
  end

  describe '.from_user non-calibrated assignment' do
    let(:student) { create(:user, :student) }
    let(:instructor) { create(:user, :instructor) }
    let(:assignment) { create(:assignment, instructor: instructor, is_calibrated: false) }

    it 'lists assignment without requiring a calibration map' do
      create(:assignment_participant, user: student, assignment: assignment, parent_id: assignment.id, handle: student.name)
      tasks = StudentTask.from_user(student)
      expect(tasks.size).to eq(1)
    end
  end

end