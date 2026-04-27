# frozen_string_literal: true

require 'rails_helper'

# Unit tests for Reports::CalibrationReport – the service that replaced the
# former CalibrationPerItemSummary class.  These specs exercise the accumulate /
# per-item-summary logic directly (without going through the HTTP layer) so that
# bucket counting and latest-response selection are validated in isolation.
RSpec.describe Reports::CalibrationReport do
  # -------------------------------------------------------------------------
  # Shared setup
  # -------------------------------------------------------------------------
  let(:assignment) { create(:assignment) }
  let(:reviewee_team) { create(:assignment_team, assignment: assignment) }
  let(:instructor_participant) { create(:assignment_participant, assignment: assignment) }
  let(:instructor_map) do
    create(:review_response_map, :for_calibration,
           assignment: assignment,
           reviewer: instructor_participant,
           reviewee: reviewee_team)
  end

  let(:questionnaire) do
    Questionnaire.create!(
      name: "Calibration Rubric #{SecureRandom.hex(4)}",
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: Instructor.find(instructor_participant.user_id)
    )
  end

  let!(:code_quality) { create(:item, questionnaire: questionnaire, txt: 'Code quality', seq: 1) }
  let!(:documentation) { create(:item, questionnaire: questionnaire, txt: 'Documentation', seq: 2) }

  before do
    AssignmentQuestionnaire.create!(
      assignment: assignment,
      questionnaire: questionnaire,
      used_in_round: 1
    )
  end

  def make_response(map:, submitted:, scores:, updated_at: Time.current)
    r = Response.create!(
      response_map: map, round: 1, version_num: 1,
      is_submitted: submitted, created_at: updated_at, updated_at: updated_at
    )
    scores.each do |item, score|
      Answer.create!(response: r, item: item,
                     answer: score[:answer], comments: score[:comments])
    end
    r
  end

  # -------------------------------------------------------------------------
  describe '#render' do
    it 'accumulates bucket counts from submitted student responses' do
      make_response(
        map: instructor_map, submitted: true,
        scores: {
          code_quality => { answer: 4, comments: 'Clear implementation' },
          documentation => { answer: 5, comments: 'Complete docs' }
        }
      )

      student_participant = create(:assignment_participant, assignment: assignment)
      student_map = create(:review_response_map, :for_calibration,
                           assignment: assignment,
                           reviewer: student_participant,
                           reviewee: reviewee_team)
      make_response(
        map: student_map, submitted: true,
        scores: {
          code_quality => { answer: 3, comments: 'Mostly clear' },
          documentation => { answer: 5, comments: 'Strong docs' }
        }
      )

      result = described_class.new(instructor_map).render

      cq_summary = result[:per_item_summary].find { |s| s[:item_id] == code_quality.id }
      expect(cq_summary[:instructor_score]).to eq(4)
      expect(cq_summary[:bucket_counts]['3']).to eq(1)
      expect(cq_summary[:bucket_counts]['4']).to eq(0)
      expect(cq_summary[:student_response_count]).to eq(1)

      doc_summary = result[:per_item_summary].find { |s| s[:item_id] == documentation.id }
      expect(doc_summary[:instructor_score]).to eq(5)
      expect(doc_summary[:bucket_counts]['5']).to eq(1)
    end

    it 'uses only the latest submitted response per student map, ignoring older or draft responses' do
      make_response(
        map: instructor_map, submitted: true,
        scores: { code_quality => { answer: 4 }, documentation => { answer: 5 } }
      )

      student_participant = create(:assignment_participant, assignment: assignment)
      student_map = create(:review_response_map, :for_calibration,
                           assignment: assignment,
                           reviewer: student_participant,
                           reviewee: reviewee_team)

      make_response(map: student_map, submitted: true,  updated_at: 2.days.ago,
                    scores: { code_quality => { answer: 1 }, documentation => { answer: 2 } })
      make_response(map: student_map, submitted: true,  updated_at: 1.day.ago,
                    scores: { code_quality => { answer: 3 }, documentation => { answer: 2 } })
      make_response(map: student_map, submitted: false, updated_at: 1.hour.ago,
                    scores: { code_quality => { answer: 5 }, documentation => { answer: 5 } })

      result = described_class.new(instructor_map).render

      cq = result[:per_item_summary].find { |s| s[:item_id] == code_quality.id }
      expect(cq[:bucket_counts]['3']).to eq(1)
      expect(cq[:bucket_counts]['1']).to eq(0)
      expect(cq[:bucket_counts]['5']).to eq(0)
    end

    it 'raises InstructorResponseMissing when the instructor has not submitted' do
      expect { described_class.new(instructor_map).render }
        .to raise_error(Reports::CalibrationReport::InstructorResponseMissing)
    end

    it 'raises InstructorResponseMissing when the instructor response is a draft' do
      make_response(map: instructor_map, submitted: false,
                    scores: { code_quality => { answer: 4 } })

      expect { described_class.new(instructor_map).render }
        .to raise_error(Reports::CalibrationReport::InstructorResponseMissing)
    end
  end
end
