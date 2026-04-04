# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe ExportHelper, type: :helper do
  describe 'graph export via Export.perform' do
    it 'returns export payloads for each class in the graph with real db records' do
      role = create(:role, :instructor)
      institution = create(:institution)
      instructor = Instructor.create!(
        name: 'exportinstructor',
        email: 'exportinstructor@example.com',
        full_name: 'Export Instructor',
        password: 'password',
        role: role,
        institution: institution
      )

      questionnaire_record = Questionnaire.create!(
        name: 'Graph Export Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'instructions'
      )

      item_record = Item.create!(
        questionnaire: questionnaire_record,
        txt: 'How clear was the design?',
        weight: 5,
        seq: 1,
        question_type: 'Scale',
        break_before: true
      )

      advice_record = QuestionAdvice.create!(
        item: item_record,
        score: 4,
        advice: 'Add concrete examples to improve clarity.'
      )

      assignment_record = create(:assignment, instructor: instructor)
      reviewer_participant = create(:assignment_participant, assignment: assignment_record)
      reviewee_participant = create(:assignment_participant, assignment: assignment_record)

      response_map_record = ResponseMap.create!(
        reviewer_id: reviewer_participant.id,
        reviewee_id: reviewee_participant.id,
        reviewed_object_id: assignment_record.id
      )

      response_record = Response.create!(
        map_id: response_map_record.id,
        additional_comment: 'response comment'
      )

      answer_record = Answer.create!(
        item: item_record,
        response: response_record,
        answer: 3,
        comments: 'Strong rationale.'
      )

      questionnaire_external = Item.external_classes.find { |ext| ext.ref_class == Questionnaire }
      allow(Item).to receive(:external_classes).and_return([questionnaire_external].compact)

      result = Export.perform(Questionnaire, nil)
      exports_by_class = result.index_by { |entry| entry[:name] }

      expect(result).to all(include(:name, :contents))
      expect(exports_by_class.keys).to include('Questionnaire', 'Item', 'QuestionAdvice', 'Answer')

      questionnaire_rows = CSV.parse(exports_by_class['Questionnaire'][:contents], headers: true)
      item_rows = CSV.parse(exports_by_class['Item'][:contents], headers: true)
      advice_rows = CSV.parse(exports_by_class['QuestionAdvice'][:contents], headers: true)
      answer_rows = CSV.parse(exports_by_class['Answer'][:contents], headers: true)

      expect(questionnaire_rows.map { |row| row['name'] }).to include(questionnaire_record.name)
      expect(item_rows.map { |row| row['txt'] }).to include(item_record.txt)
      expect(advice_rows.map { |row| row['advice'] }).to include(advice_record.advice)
      expect(answer_rows.map { |row| row['comments'] }).to include(answer_record.comments)
      expect(answer_rows.map { |row| row['answer'] }).to include(answer_record.answer.to_s)
      expect(answer_rows.headers.length).to eq(
        answer_rows.first&.fields&.length || answer_rows.headers.length
      )
    end

    it 'exports csv and prints each class csv output' do
      role = create(:role, :instructor)
      institution = create(:institution)
      instructor = Instructor.create!(
        name: 'csvprintinstructor',
        email: 'csvprintinstructor@example.com',
        full_name: 'CSV Print Instructor',
        password: 'password',
        role: role,
        institution: institution
      )

      questionnaire_record = Questionnaire.create!(
        name: 'CSV Print Questionnaire',
        instructor: instructor,
        private: false,
        min_question_score: 0,
        max_question_score: 10,
        questionnaire_type: 'ReviewQuestionnaire',
        display_type: 'Likert',
        instruction_loc: 'instructions'
      )

      item_record = Item.create!(
        questionnaire: questionnaire_record,
        txt: 'What should improve?',
        weight: 2,
        seq: 1,
        question_type: 'Scale',
        break_before: true
      )

      QuestionAdvice.create!(
        item: item_record,
        score: 2,
        advice: 'Consider edge cases.'
      )

      assignment_record = create(:assignment, instructor: instructor)
      reviewer_participant = create(:assignment_participant, assignment: assignment_record)
      reviewee_participant = create(:assignment_participant, assignment: assignment_record)
      response_map_record = ResponseMap.create!(
        reviewer_id: reviewer_participant.id,
        reviewee_id: reviewee_participant.id,
        reviewed_object_id: assignment_record.id
      )
      response_record = Response.create!(
        map_id: response_map_record.id,
        additional_comment: 'print response comment'
      )
      Answer.create!(
        item: item_record,
        response: response_record,
        answer: 1,
        comments: 'Needs work.'
      )

      questionnaire_external = Item.external_classes.find { |ext| ext.ref_class == Questionnaire }
      allow(Item).to receive(:external_classes).and_return([questionnaire_external].compact)

      result = Export.perform(Questionnaire, nil)
      exports_by_class = result.index_by { |entry| entry[:name] }

      puts "\nCSV Exports:"
      result.each do |export_entry|
        puts "--- #{export_entry[:name]} ---"
        puts export_entry[:contents]
      end

      expect(exports_by_class.keys).to include('Questionnaire', 'Item', 'QuestionAdvice', 'Answer')
      expect(exports_by_class['Questionnaire'][:contents]).to include('name')
      expect(exports_by_class['Item'][:contents]).to include('txt')
      expect(exports_by_class['QuestionAdvice'][:contents]).to include('advice')
      expect(exports_by_class['Answer'][:contents]).to include('comments')

      answer_rows = CSV.parse(exports_by_class['Answer'][:contents], headers: true)
      expect(answer_rows.headers.length).to eq(
        answer_rows.first&.fields&.length || answer_rows.headers.length
      )
    end
  end
end
