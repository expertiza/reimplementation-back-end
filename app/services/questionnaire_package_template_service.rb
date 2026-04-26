# frozen_string_literal: true

require 'csv'
require 'json'
require 'zip'

# Generates blank questionnaire package templates from the import/export schema.
class QuestionnairePackageTemplateService
  TEMPLATE_DEFINITIONS = {
    'questionnaires' => {
      filename: 'questionnaires_import_sample.csv',
      headers: QuestionnairePackageExportService::QUESTIONNAIRE_HEADERS,
      sample_row: [
        'Sample Review Questionnaire',
        'ReviewQuestionnaire',
        'Likert',
        'false',
        '0',
        '5',
        'seed/review_instructions',
        'instructor_username'
      ]
    },
    'items' => {
      filename: 'items_import_sample.csv',
      headers: QuestionnairePackageExportService::ITEM_HEADERS,
      sample_row: [
        'Sample Review Questionnaire',
        'instructor_username',
        '1',
        'How clear is the submitted work?',
        'Scale',
        '1',
        'true',
        'Needs work',
        'Excellent',
        '',
        ''
      ]
    },
    'question_advices' => {
      filename: 'question_advices_import_sample.csv',
      headers: QuestionnairePackageExportService::QUESTION_ADVICE_HEADERS,
      sample_row: [
        'Sample Review Questionnaire',
        'instructor_username',
        '1',
        'How clear is the submitted work?',
        '5',
        'Mention the strongest evidence and reasoning.'
      ]
    }
  }.freeze

  PACKAGE_TEMPLATE_NAME = 'package'

  def initialize(template_name:)
    @template_name = template_name.to_s
  end

  def perform
    return package_template if @template_name == PACKAGE_TEMPLATE_NAME

    csv_template
  end

  private

  def csv_template
    definition = TEMPLATE_DEFINITIONS[@template_name]
    raise StandardError, "Unsupported questionnaire package template: #{@template_name}" if definition.nil?

    {
      filename: definition[:filename],
      content_type: 'text/csv',
      data: build_csv(definition)
    }
  end

  def package_template
    {
      filename: 'questionnaire_package_import_sample.zip',
      content_type: 'application/zip',
      data: build_package_zip
    }
  end

  def build_package_zip
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry('manifest.json')
      zip.write(
        JSON.pretty_generate(
          {
            package_type: QuestionnairePackageExportService::PACKAGE_TYPE,
            version: QuestionnairePackageExportService::VERSION,
            files: QuestionnairePackageExportService::FILES,
            includes: QuestionnairePackageExportService::INCLUDED_RESOURCES,
            excludes: QuestionnairePackageExportService::EXCLUDED_RESOURCES
          }
        )
      )

      TEMPLATE_DEFINITIONS.each_value do |definition|
        zip.put_next_entry(package_csv_filename(definition[:filename]))
        zip.write(build_csv(definition))
      end
    end.string
  end

  def package_csv_filename(filename)
    filename.sub('_import_sample', '')
  end

  def build_csv(definition)
    CSV.generate do |csv|
      csv << definition[:headers]
      csv << definition[:sample_row]
    end
  end
end
