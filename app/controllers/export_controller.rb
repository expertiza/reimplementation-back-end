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

    csv_file = Export.perform(params[:class].constantize, ordered_fields)


    render json: { message: "#{params[:class]} has been imported!", file: csv_file }, status: :ok

  end

  private
  def export_params
    puts params
    params.permit(:class, :ordered_fields)
  end
end