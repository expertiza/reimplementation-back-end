# This file holds the logic for exporting data from the application to various formats.

class ExportController < ApplicationController
  before_action :export_params
  def index
    imported_class = params[:class].constantize

    render json: {
      mandatory_fields: imported_class.mandatory_fields,
      optional_fields: imported_class.optional_fields,
      external_fields: imported_class.external_fields
    }, status: :ok
  end

  def export
    ordered_fields = JSON.parse(params[:ordered_fields]) if params[:ordered_fields]

    params[:class].constantize.try_import_records(uploaded_file, ordered_fields, use_header: use_headers)

    # Logic for exporting data
    data = DataExporter.new.export(format: params[:format])
    send_data data, filename: "exported_data.#{params[:format]}"

    render json: { message: "#{params[:class].name} has been imported!" }, status: :ok

  end

  private
  def export_params
    puts params
    params.permit(:class, :ordered_fields)
  end
end