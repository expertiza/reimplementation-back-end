# This file defines a service class for handling data import operations.

module Services
  class Import
    def initialize(file_path)
      @file_path = file_path
    end

    def perform
      data = read_file
      parsed_data = parse_data(data)
      save_data(parsed_data)
    end

    private

    def read_file
      File.read(@file_path)
    rescue Errno::ENOENT
      raise "File not found: #{@file_path}"
    end

    def parse_data(data)
      # Assuming the data is in CSV format for this example
      require 'csv'
      CSV.parse(data, headers: true)
    end

    def save_data(parsed_data)
      parsed_data.each do |row|
        # Assuming we are importing into a Model called Record
        Record.create!(row.to_h)
      end
    end
  end
end