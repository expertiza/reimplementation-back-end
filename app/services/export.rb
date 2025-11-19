# This file defines a service class for handling data export operations.
class Export
  def initialize(data)
    @data = data
  end

  def to_csv
    CSV.generate do |csv|
      csv << @data.first.keys # Add headers
      @data.each do |row|
        csv << row.values
      end
    end
  end

  def to_json
    @data.to_json
  end

  def to_xml
    @data.to_xml(root: 'records', skip_types: true)
  end
end