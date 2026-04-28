# frozen_string_literal: true

require 'base64'

# Custom package workflow for questionnaire templates. The generic import/export
# endpoints handle one model at a time, but templates must move questionnaires,
# items, and advice together while excluding responses and quiz data.
class QuestionnairePackagesController < ApplicationController
  ALLOWED_DUPLICATE_ACTIONS = {
    'SkipRecordAction' => SkipRecordAction,
    'UpdateExistingRecordAction' => UpdateExistingRecordAction,
    'ChangeOffendingFieldAction' => ChangeOffendingFieldAction
  }.freeze

  before_action :questionnaire_package_params

  # Exposes the package contract used by the import modal.
  def package_config
    render json: {
      required_files: QuestionnairePackageImportService::REQUIRED_FILES,
      csv_header_requirements: QuestionnairePackageImportService::CSV_HEADER_REQUIREMENTS,
      available_templates: available_templates,
      package_type: QuestionnairePackageImportService::PACKAGE_TYPE,
      version: QuestionnairePackageImportService::VERSION,
      available_actions_on_dup: ALLOWED_DUPLICATE_ACTIONS.keys
    }, status: :ok
  end

  # Downloads blank CSV templates or a full blank package zip.
  def template
    package_template = QuestionnairePackageTemplateService.new(template_name: params[:template_name]).perform

    render json: {
      filename: package_template[:filename],
      content_type: package_template[:content_type],
      data: Base64.strict_encode64(package_template[:data])
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Returns the related CSVs as one base64 zip for the JSON API.
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

  # Imports either an exported zip or role-specific CSV uploads. This stays
  # custom because cross-file links are required to rebuild templates correctly.
  def import
    dup_action = duplicate_action_for(params[:dup_action])
    result = QuestionnairePackageImportService.new(
      package_file: params[:package_file],
      questionnaire_file: params[:questionnaire_file],
      items_file: params[:items_file],
      question_advices_file: params[:question_advices_file],
      dup_action: dup_action
    ).perform

    render json: { message: 'Questionnaire template package has been imported!', **result }, status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Dry-runs the same inputs as import so users can inspect row actions first.
  def preview
    dup_action = duplicate_action_for(params[:dup_action])
    result = QuestionnairePackageImportService.new(
      package_file: params[:package_file],
      questionnaire_file: params[:questionnaire_file],
      items_file: params[:items_file],
      question_advices_file: params[:question_advices_file],
      dup_action: dup_action
    ).preview

    render json: result, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def available_templates
    QuestionnairePackageTemplateService::TEMPLATE_DEFINITIONS.keys + [QuestionnairePackageTemplateService::PACKAGE_TEMPLATE_NAME]
  end

  # Permit package-only fields without mixing them into questionnaire params.
  def questionnaire_package_params
    params.permit(
      :package_file,
      :questionnaire_file,
      :items_file,
      :question_advices_file,
      :dup_action,
      :export_all,
      questionnaire_ids: []
    )
  end

  # Multipart export forms may send IDs as an array or JSON string.
  def parse_questionnaire_ids
    ids = params[:questionnaire_ids]
    return ids if ids.is_a?(Array)
    return [] if ids.blank?

    JSON.parse(ids)
  rescue JSON::ParserError
    []
  end

  # Reuse duplicate-action classes through a package-specific allowlist.
  def duplicate_action_for(action_name)
    return nil if action_name.blank?

    action_class = ALLOWED_DUPLICATE_ACTIONS[action_name]
    raise StandardError, "Unsupported duplicate action: #{action_name}" if action_class.nil?

    action_class.new
  end
end
