# This file is used to map fields from an external data source to the internal data model.
class FieldMapping
  def initialize(data)
    @data = data
  end

  def map
    @data.map do |record|
      {
        internal_field_1: record[:external_field_a],
        internal_field_2: record[:external_field_b],
        internal_field_3: transform_field(record[:external_field_c])
      }
    end
  end

  private

  def transform_field(value)
    # Example transformation logic
    value.strip.upcase
  end
end