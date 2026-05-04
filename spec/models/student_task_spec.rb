# frozen_string_literal: true

require 'rails_helper'


RSpec.describe StudentTask, type: :model do
  before(:each) do
    @assignment = double(name: "Final Project", id: 99, require_quiz: false)
    @participant = double(
      id: 1,
      assignment: @assignment,
      topic: "E2442",
      current_stage: "finished",
      stage_deadline: "2024-04-23",
      permission_granted: true
    )
    # E2619: create_from_participant queries ReviewResponseMap and QuizResponseMap.
    # Stub them out so unit tests don't hit the database.
    allow(ReviewResponseMap).to receive(:where).with(reviewer_id: 1).and_return([])
    allow(QuizResponseMap).to receive(:where).and_return(double(joins: double(where: double(exists?: false))))
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

      expect(student_task.assignment).to eq(@participant.assignment.name)
      expect(student_task.assignment_id).to eq(@participant.assignment.id)
      expect(student_task.topic).to eq(@participant.topic)
      expect(student_task.current_stage).to eq(@participant.current_stage)
      expect(student_task.stage_deadline).to eq(Time.parse(@participant.stage_deadline))
      expect(student_task.permission_granted).to be @participant.permission_granted
      expect(student_task.participant).to be @participant
      # E2619: quiz fields should be present (no reviewee team => no quiz questionnaire)
      expect(student_task.require_quiz).to be false
      expect(student_task.quiz_taken).to be false
      expect(student_task.has_quiz_questionnaire).to be false
      expect(student_task.quiz_questionnaire_id).to be_nil
    end

    it "returns nil when the participant has no assignment" do
      participant_no_asgn = double(assignment: nil, id: 2)
      expect(StudentTask.create_from_participant(participant_no_asgn)).to be_nil
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
      allow(Participant).to receive(:find_by).with(id: 1).and_return(@participant)

      expect(Participant).to receive(:find_by).with(id: 1).and_return(@participant)
      expect(StudentTask).to receive(:create_from_participant).with(@participant)

      StudentTask.from_participant_id(1)
    end
  end

  describe "#as_json" do
    it "includes quiz fields in the serialised hash" do
      task = StudentTask.new(
        assignment:             "Final Project",
        assignment_id:          99,
        current_stage:          "finished",
        participant:            @participant,
        stage_deadline:         "2024-04-23",
        topic:                  "E2442",
        permission_granted:     true,
        require_quiz:           true,
        quiz_taken:             false,
        has_quiz_questionnaire: true,
        quiz_questionnaire_id:  42
      )
      json = task.as_json
      expect(json[:assignment_id]).to eq(99)
      expect(json[:require_quiz]).to be true
      expect(json[:quiz_taken]).to be false
      expect(json[:has_quiz_questionnaire]).to be true
      expect(json[:quiz_questionnaire_id]).to eq(42)
      expect(json[:participant_id]).to eq(@participant.id)
    end
  end

end