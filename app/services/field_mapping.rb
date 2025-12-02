# app/services/field_mapping.rb
class FieldMapping
  attr_reader :model_class, :ordered_fields

  # model_class: an ActiveRecord class (User, Assignment, Team, etc.)
  # ordered_fields: array of symbols/strings like [:email, :last_name]
  def initialize(model_class, ordered_fields)
    @model_class    = model_class
    @ordered_fields = ordered_fields.map(&:to_s)
  end

  # Build mapping from a CSV header row
  # header_row is an array like ["Email", "Last Name", "First Name"]
  def self.from_header(model_class, header_row)
    header_row = header_row.map { |h| h.to_s.strip }

    valid_fields = model_class.internal_and_external_fields.map(&:to_s)

    matched = header_row.filter_map do |h|
      valid_fields.find { |f| f.casecmp?(h) }
    end

    new(model_class, matched)
  end

  # Return CSV header row
  def headers
    ordered_fields
  end

  def duplicate_headers
    ordered_fields
      .group_by { |h| h }
      .select   { |_k, v| v.size > 1 }
      .keys
  end

  # Return values in correct order for a record
  def values_for(record)
    ordered_fields.map { |f| record.public_send(f) }
  end

  # JSON-friendly
  def to_h
    {
      model_class: model_class.name,
      ordered_fields: ordered_fields
    }
  end
end
