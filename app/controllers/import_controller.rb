# This file holds the logic for importing data from external sources into the application.

class ImportController < ApplicationController
  before_action :import_params
  def index
    imported_class = params[:class].constantize

    render json: {
      mandatory_fields: imported_class.mandatory_fields,
      optional_fields: imported_class.optional_fields,
      external_fields: imported_class.external_fields,
      available_actions_on_dup: [] # Only for import
    }, status: :ok
  end

  def import
    uploaded_file = params[:csv_file]
    use_headers = ActiveRecord::Type::Boolean.new.deserialize(params[:use_headers])
    ordered_fields = JSON.parse(params[:ordered_fields]) if params[:ordered_fields]

    params[:class].constantize.try_import_records(uploaded_file, ordered_fields, use_header: use_headers)

    render json: { message: "#{params[:class].name} has been imported!" }, status: :created

  rescue StandardError => e
      puts "An unexpected error occurred: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
  end

  private
  def import_params
    params.permit(:csv_file, :use_headers, :class, :ordered_fields)
  end
end