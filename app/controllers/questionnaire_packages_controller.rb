# frozen_string_literal: true

require 'base64'

class QuestionnairePackagesController < ApplicationController
  ALLOWED_DUPLICATE_ACTIONS = {
    'SkipRecordAction' => SkipRecordAction,
    'UpdateExistingRecordAction' => UpdateExistingRecordAction,
    'ChangeOffendingFieldAction' => ChangeOffendingFieldAction
  }.freeze

  before_action :questionnaire_package_params

  def package_config
    render json: {
      required_files: QuestionnairePackageImportService::REQUIRED_FILES,
      package_type: QuestionnairePackageImportService::PACKAGE_TYPE,
      version: QuestionnairePackageImportService::VERSION,
      available_actions_on_dup: ALLOWED_DUPLICATE_ACTIONS.keys
    }, status: :ok
  end

  def export
    questionnaire_ids = parse_questionnaire_ids
    export_all = ActiveRecord::Type::Boolean.new.deserialize(params[:export_all])
    if questionnaire_ids.blank? && !export_all
      render json: { error: 'Select one or more questionnaires to export, or choose export all.' }, status: :unprocessable_entity
      return
    end

    scope = questionnaire_ids.present? ? Questionnaire.where(id: questionnaire_ids) : Questionnaire.all
    package = QuestionnairePackageExportService.new(questionnaires: scope).perform

    render json: {
      message: 'Questionnaire template package has been exported!',
      filename: package[:filename],
      content_type: package[:content_type],
      data: Base64.strict_encode64(package[:data]),
      counts: package[:counts]
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def import
    uploaded_file = params[:package_file]
    dup_action = duplicate_action_for(params[:dup_action])
    result = QuestionnairePackageImportService.new(file: uploaded_file, dup_action: dup_action).perform

    render json: { message: 'Questionnaire template package has been imported!', **result }, status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def questionnaire_package_params
    params.permit(:package_file, :dup_action, :export_all, questionnaire_ids: [])
  end

  def parse_questionnaire_ids
    ids = params[:questionnaire_ids]
    return ids if ids.is_a?(Array)
    return [] if ids.blank?

    JSON.parse(ids)
  rescue JSON::ParserError
    []
  end

  def duplicate_action_for(action_name)
    return nil if action_name.blank?

    action_class = ALLOWED_DUPLICATE_ACTIONS[action_name]
    raise StandardError, "Unsupported duplicate action: #{action_name}" if action_class.nil?

    action_class.new
  end
end
