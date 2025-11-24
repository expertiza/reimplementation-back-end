# This file holds the logic for importing data from external sources into the application.

class Import
  def initialize(source)
    @source = source
  end

  def perform
    data = fetch_data
    mapped_data = map_fields(data)
    save_data(mapped_data)
  end

  private

  def fetch_data
    # Logic to fetch data from the external source
    @source.get_data
  end

  def map_fields(data)
    # Logic to map fields from external data to internal model
    FieldMapping.new(data).map
  end

  def save_data(mapped_data)
    # Logic to save the mapped data into the application database
    mapped_data.each do |record|
      Model.create(record)
    end
  end
end