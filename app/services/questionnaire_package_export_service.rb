# frozen_string_literal: true

require 'csv'
require 'json'
require 'zip'

class QuestionnairePackageExportService
  PACKAGE_TYPE = 'questionnaire_template_export'
  VERSION = 1
  FILES = %w[questionnaires.csv items.csv question_advices.csv].freeze
  INCLUDED_RESOURCES = %w[questionnaires items question_advices].freeze
  EXCLUDED_RESOURCES = %w[answers responses quiz_questionnaires quiz_items quiz_question_choices].freeze

  QUESTIONNAIRE_HEADERS = %w[
    name
    questionnaire_type
    display_type
    private
    min_question_score
    max_question_score
    instruction_loc
    instructor_name
  ].freeze

  ITEM_HEADERS = %w[
    questionnaire_name
    questionnaire_instructor_name
    seq
    txt
    question_type
    weight
    break_before
    min_label
    max_label
    alternatives
    size
  ].freeze

  QUESTION_ADVICE_HEADERS = %w[
    questionnaire_name
    questionnaire_instructor_name
    item_seq
    item_txt
    score
    advice
  ].freeze

  def initialize(questionnaires: nil)
    @questionnaires = questionnaires
  end

  def perform
    exportable_questionnaires = questionnaire_scope
      .includes(items: :question_advices)
      .order(:id)

    questionnaire_csv = build_csv(QUESTIONNAIRE_HEADERS, questionnaire_rows(exportable_questionnaires))
    item_csv = build_csv(ITEM_HEADERS, item_rows(exportable_questionnaires))
    question_advice_csv = build_csv(QUESTION_ADVICE_HEADERS, question_advice_rows(exportable_questionnaires))

    zip_data = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry('manifest.json')
      zip.write(
        JSON.pretty_generate(
          {
            package_type: PACKAGE_TYPE,
            version: VERSION,
            files: FILES,
            includes: INCLUDED_RESOURCES,
            excludes: EXCLUDED_RESOURCES,
            exported_at: Time.zone.now.iso8601,
            questionnaire_count: exportable_questionnaires.size
          }
        )
      )

      zip.put_next_entry('questionnaires.csv')
      zip.write(questionnaire_csv)

      zip.put_next_entry('items.csv')
      zip.write(item_csv)

      zip.put_next_entry('question_advices.csv')
      zip.write(question_advice_csv)
    end

    {
      filename: "questionnaire_template_package_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.zip",
      content_type: 'application/zip',
      data: zip_data.string,
      counts: {
        questionnaires: exportable_questionnaires.size,
        items: exportable_questionnaires.sum { |questionnaire| exportable_items_for(questionnaire).size },
        question_advices: exportable_questionnaires.sum do |questionnaire|
          exportable_items_for(questionnaire).sum { |item| item.question_advices.size }
        end
      }
    }
  end

  private

  def questionnaire_scope
    scope = @questionnaires || Questionnaire.all
    scope.where.not(questionnaire_type: 'QuizQuestionnaire')
  end

  def questionnaire_rows(questionnaires)
    questionnaires.map do |questionnaire|
      [
        questionnaire.name,
        questionnaire.questionnaire_type,
        questionnaire.display_type,
        questionnaire.private,
        questionnaire.min_question_score,
        questionnaire.max_question_score,
        questionnaire.instruction_loc,
        questionnaire.instructor&.name
      ]
    end
  end

  def item_rows(questionnaires)
    questionnaires.flat_map do |questionnaire|
      exportable_items_for(questionnaire).map do |item|
        [
          questionnaire.name,
          questionnaire.instructor&.name,
          item.seq,
          item.txt,
          item.question_type,
          item.weight,
          item.break_before,
          item.min_label,
          item.max_label,
          item.alternatives,
          item.size
        ]
      end
    end
  end

  def question_advice_rows(questionnaires)
    questionnaires.flat_map do |questionnaire|
      exportable_items_for(questionnaire).flat_map do |item|
        item.question_advices.map do |question_advice|
          [
            questionnaire.name,
            questionnaire.instructor&.name,
            item.seq,
            item.txt,
            question_advice.score,
            question_advice.advice
          ]
        end
      end
    end
  end

  def exportable_items_for(questionnaire)
    questionnaire.items.reject do |item|
      item.question_type.to_s.casecmp('multiple_choice').zero? || item.is_a?(QuizItem)
    end
  end

  def build_csv(headers, rows)
    CSV.generate do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
  end
end
