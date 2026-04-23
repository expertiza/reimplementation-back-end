# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalibrationPerItemSummary do
  describe '.build' do
    it 'summarizes submitted student scores by rubric item and includes instructor scores' do
      questionnaire = create_questionnaire
      code_quality = create(:item, questionnaire: questionnaire, txt: 'Code quality', seq: 1)
      documentation = create(:item, questionnaire: questionnaire, txt: 'Documentation', seq: 2)
      code_quality.update!(seq: 1)
      documentation.update!(seq: 2)
      assignment = create(:assignment)

      instructor_map = create(:review_response_map, :for_calibration, assignment: assignment)
      instructor_response = create_response(
        map: instructor_map,
        submitted: true,
        scores: {
          code_quality => { answer: 4, comments: 'Clear implementation' },
          documentation => { answer: 5, comments: 'Very complete' }
        }
      )

      student_map_one = create(:review_response_map, :for_calibration, assignment: assignment)
      student_map_two = create(:review_response_map, :for_calibration, assignment: assignment)

      create_response(
        map: student_map_one,
        submitted: true,
        updated_at: 2.days.ago,
        scores: {
          code_quality => { answer: 1 },
          documentation => { answer: 2 }
        }
      )
      latest_student_one = create_response(
        map: student_map_one,
        submitted: true,
        updated_at: 1.day.ago,
        scores: {
          code_quality => { answer: 3 },
          documentation => { answer: 2 }
        }
      )
      latest_student_two = create_response(
        map: student_map_two,
        submitted: true,
        updated_at: 3.hours.ago,
        scores: {
          code_quality => { answer: 3 }
        }
      )
      unsubmitted_student_response = create_response(
        map: student_map_two,
        submitted: false,
        updated_at: 1.hour.ago,
        scores: {
          code_quality => { answer: 5 },
          documentation => { answer: 5 }
        }
      )

      summary = described_class.build(
        items: [documentation, code_quality],
        instructor_response: instructor_response,
        student_responses: [
          latest_student_two,
          unsubmitted_student_response,
          latest_student_one
        ]
      )

      expect(summary).to eq([
        {
          item_id: code_quality.id,
          item_label: 'Code quality',
          item_seq: code_quality.seq,
          instructor_score: 4,
          instructor_comment: 'Clear implementation',
          bucket_counts: {
            '0' => 0,
            '1' => 0,
            '2' => 0,
            '3' => 2,
            '4' => 0,
            '5' => 0
          },
          student_response_count: 2
        },
        {
          item_id: documentation.id,
          item_label: 'Documentation',
          item_seq: documentation.seq,
          instructor_score: 5,
          instructor_comment: 'Very complete',
          bucket_counts: {
            '0' => 0,
            '1' => 0,
            '2' => 1,
            '3' => 0,
            '4' => 0,
            '5' => 0
          },
          student_response_count: 2
        }
      ])
    end

    it 'uses the latest submitted response per map even when a newer draft exists' do
      questionnaire = create_questionnaire
      item = create(:item, questionnaire: questionnaire, txt: 'Accuracy', seq: 1)
      assignment = create(:assignment)
      response_map = create(:review_response_map, :for_calibration, assignment: assignment)

      submitted_response = create_response(
        map: response_map,
        submitted: true,
        updated_at: 2.hours.ago,
        scores: {
          item => { answer: 2 }
        }
      )
      draft_response = create_response(
        map: response_map,
        submitted: false,
        updated_at: 1.hour.ago,
        scores: {
          item => { answer: 5 }
        }
      )

      summary = described_class.build(
        items: [item],
        instructor_response: nil,
        student_responses: [submitted_response, draft_response]
      )

      expect(summary.first[:bucket_counts]['2']).to eq(1)
      expect(summary.first[:bucket_counts]['5']).to eq(0)
      expect(summary.first[:student_response_count]).to eq(1)
    end
  end

  def create_response(map:, submitted:, scores:, updated_at: Time.current)
    response = Response.create!(
      response_map: map,
      round: 1,
      version_num: 1,
      is_submitted: submitted,
      created_at: updated_at,
      updated_at: updated_at
    )

    scores.each do |item, score|
      Answer.create!(
        response: response,
        item: item,
        answer: score[:answer],
        comments: score[:comments]
      )
    end

    response
  end

  def create_questionnaire
    Questionnaire.create!(
      name: "Calibration Rubric #{SecureRandom.hex(4)}",
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: create_instructor
    )
  end

  def create_instructor
    Instructor.create!(
      name: "instructor_#{SecureRandom.hex(4)}",
      email: "instructor_#{SecureRandom.hex(4)}@example.com",
      password: 'password',
      full_name: 'Calibration Instructor',
      role: create(:role, name: "Instructor #{SecureRandom.hex(4)}"),
      institution: create(:institution)
    )
  end
end
