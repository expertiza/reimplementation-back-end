# This file holds the logic for importing data from external sources into the application.

class ImportController < ApplicationController
  before_action :import_params
  def index
    imported_class = params[:class].constantize
    mapping = FieldMapping.new(imported_class, ["name", "id", "email"])

    p mapping.duplicate_headers
  end

  def import
    uploaded_file = params[:csv_file]
    use_headers = ActiveRecord::Type::Boolean.new.deserialize(params[:use_headers])
    ordered_fields = JSON.parse(params[:ordered_fields]) if params[:ordered_fields]

    params[:class].constantize.try_import_records(uploaded_file, ordered_fields, use_header: use_headers)
  end

  private
  def import_params
    params.permit(:csv_file, :use_headers, :class, :ordered_fields)
  end
end