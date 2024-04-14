require 'rails_helper'


RSpec.describe StudentTask, type: :model do

  describe ".initialize" do
    it "correctly assigns all attributes" do
      args = {
        assignment: "Final Project",
        current_stage: "finished",
        participant: "John Doe",
        stage_deadline: "2024-04-23",
        topic: "E2442"
      }
      student_task = StudentTask.new(args)
      expect(student_task.assignment).to eq("Final Project")
      expect(student_task.current_stage).to eq("finished")
      expect(student_task.participant).to eq("John Doe")
      expect(student_task.stage_deadline).to eq("2024-04-23")
      expect(student_task.topic).to eq("E2442")
    end
  end

  describe ".from_participant" do
    it "creates an instance from a participant instance" do
      # This is a simplified instance to represent participant, after the participant model is implemented
      # Please improve this test
      participant = double(
        assignment: "Final Project",
        topic: "E2442",
        current_stage: "finished",
        stage_deadline: "2024-04-23"
      )
      allow(StudentTask).to receive(:parse_stage_deadline).with("2024-04-23").and_return(Time.parse("2024-04-23"))

      student_task = StudentTask.from_participant(participant)

      expect(student_task.assignment).to eq("Final Project")
      expect(student_task.topic).to eq("E2442")
      expect(student_task.current_stage).to eq("finished")
      expect(student_task.stage_deadline).to eq(Time.parse("2024-04-23"))
    end
  end

  describe ".parse_stage_deadline" do
    context "valid date string" do
      it "parses the date string into a Time object" do
        date_string = "2024-04-25"
        expect(StudentTask.send(:parse_stage_deadline, date_string)).to eq(Time.parse("2024-04-25"))
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

end