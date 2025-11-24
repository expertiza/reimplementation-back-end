# This file holds the logic for exporting data from the application to various formats.

class ExportController < ApplicationController
  def export_data
    # Logic for exporting data
    data = DataExporter.new.export(format: params[:format])
    send_data data, filename: "exported_data.#{params[:format]}"
  end
end