# importable_exportable_helper.rb
module ImportableExportableHelper
  # This module provides methods to import and export data in various formats.

  require 'csv'
  require 'json'
  require 'yaml'

  # Exports data to the specified format.
  #
  # @param data [Array<Hash>] The data to be exported.
  # @param format [Symbol] The format to export the data in (:csv, :json, :yaml).
  # @return [String] The exported data as a string.
  def export_data(data, format)
    case format
    when :csv
      CSV.generate do |csv|
        csv << data.first.keys if data.any?
        data.each { |row| csv << row.values }
      end
    when :json
      JSON.pretty_generate(data)
    when :yaml
      data.to_yaml
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end
  end

  # Imports data from the specified format.
  #
  # @param data_string [String] The string containing the data to be imported.
  # @param format [Symbol] The format of the input data (:csv, :json, :yaml).
  # @return [Array<Hash>] The imported data as an array of hashes.
  def import_data(data_string, format)
    case format
    when :csv
      csv = CSV.parse(data_string, headers: true)
      csv.map(&:to_h)
    when :json
      JSON.parse(data_string)
    when :yaml
      YAML.safe_load(data_string)
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end
  end
end