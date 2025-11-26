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

    User.try_import_records(uploaded_file, User.import_export_fields, use_header: use_headers)
  end

  private
  def import_params
    params.permit(:csv_file, :use_headers, :class)
  end
end