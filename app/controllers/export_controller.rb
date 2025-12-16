# This controller handles exporting data from the application to various formats.
class ExportController < ApplicationController
  before_action :export_params

  def index
    klass = params[:class].constantize

    render json: {
      mandatory_fields: klass.mandatory_fields,
      optional_fields: klass.optional_fields,
      external_fields: klass.external_fields
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def export
    # Parse ordered fields from JSON, if provided
    ordered_fields =
      begin
        JSON.parse(params[:ordered_fields]) if params[:ordered_fields]
      rescue JSON::ParserError
        render json: { error: "Invalid JSON for ordered_fields" }, status: :unprocessable_entity
        return
      end

    klass = params[:class].constantize

    csv_file = Export.perform(klass, ordered_fields)

    render json: {
      message: "#{params[:class]} has been exported!",
      file: csv_file
    }, status: :ok

  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def export_params
    params.permit(:class, :ordered_fields)
  end
end
