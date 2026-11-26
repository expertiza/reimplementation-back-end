# frozen_string_literal: true

# Topic CSV upload, following the request shape of the frontend's shared import window.
class ProjectTopicImportsController < ApplicationController
  MAX_FILE_BYTES = 1.megabyte

  def action_allowed?
    return current_user_has_ta_privileges? if action_name == 'show'

    current_user_can_manage?(assignment)
  end

  # GET /import/ProjectTopic
  def show
    render json: {
      mandatory_fields: ProjectTopicCsvImport::MANDATORY_FIELDS,
      optional_fields: ProjectTopicCsvImport::OPTIONAL_FIELDS,
      external_fields: [],
      available_actions_on_dup: []
    }
  end

  # POST /import/ProjectTopic (multipart: assignment_id, csv_file, use_headers, ordered_fields)
  def create
    file = params[:csv_file]
    return render_error('Choose a CSV file.') unless file.respond_to?(:read)
    return render_error('The file is larger than 1 MB.') if file.size > MAX_FILE_BYTES

    counts = ProjectTopicCsvImport.new(
      assignment: assignment,
      content: file.read,
      use_headers: ActiveModel::Type::Boolean.new.cast(params.fetch(:use_headers, true)),
      ordered_fields: params[:ordered_fields] && JSON.parse(params[:ordered_fields])
    ).call

    render json: { message: "Topics imported: #{counts[:created]} created, #{counts[:updated]} updated.", **counts },
           status: :created
  rescue ProjectTopicCsvImport::Error => e
    render_error(e.message)
  rescue JSON::ParserError
    render_error('ordered_fields must be a JSON array.')
  end

  private

  def assignment
    @assignment ||= Assignment.find_by(id: params[:assignment_id])
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end
end
