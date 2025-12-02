# app/services/field_mapping.rb
#
# ===============================================================
# FieldMapping
#
# This class defines how CSV fields are mapped to an internal
# ActiveRecord model’s attributes. It is used by the import/export
# service layer to:
#
#   • Determine the order of fields in an exported CSV
#   • Interpret CSV rows and produce attribute hashes
#   • Build mappings based on CSV headers, if the import uses headers
#
# The mapping is intentionally simple: it stores an array of field
# names (strings) in the order that the import/export process should
# follow.
#
# ===============================================================
class FieldMapping
  attr_reader :model_class, :ordered_fields

  # --------------------------------------------------------------
  # Initialize a new mapping.
  #
  # model_class:
  #   An ActiveRecord model class (e.g., User, Team, Assignment)
  #
  # ordered_fields:
  #   Array of field names that define the order CSV fields appear
  #   in. We convert everything to strings to ensure consistent
  #   lookups (symbols vs strings cause unnecessary mismatches).
  #
  # Example:
  #   FieldMapping.new(User, [:email, "first_name", :last_name])
  #
  # Output:
  #   @ordered_fields = ["email", "first_name", "last_name"]
  # --------------------------------------------------------------
  def initialize(model_class, ordered_fields)
    @model_class    = model_class
    @ordered_fields = ordered_fields.map(&:to_s)
  end

  # --------------------------------------------------------------
  # Build a mapping using the header row from a CSV file.
  #
  # header_row:
  #   Array of strings taken from the first row of a CSV file:
  #     ["Email", "Last Name", "First Name"]
  #
  # How matching works:
  #   - Normalize headers (strip whitespace, lowercase comparison)
  #   - Compare headers case-insensitively against all internal + external
  #     fields allowed by the model.
  #   - Only headers that match valid model fields are kept.
  #
  # Example:
  #   model_class.internal_and_external_fields = [:email, :first_name, :last_name]
  #
  #   headers = ["EMAIL", "First Name", "Ignored Column"]
  #
  #   matched = ["email", "first_name"]
  #
  # --------------------------------------------------------------
  def self.from_header(model_class, header_row)
    # Normalize header strings
    header_row = header_row.map { |h| h.to_s.strip }

    # Retrieve valid model fields (convert to strings for comparison)
    valid_fields = model_class.internal_and_external_fields.map(&:to_s)

    # Match CSV headers to valid model fields (case-insensitive)
    matched = header_row.filter_map do |h|
      valid_fields.find { |f| f.casecmp?(h) }
    end

    new(model_class, matched)
  end

  # --------------------------------------------------------------
  # Returns the internal CSV header row for export.
  #
  # This is simply the list of ordered fields.
  # --------------------------------------------------------------
  def headers
    ordered_fields
  end

  # --------------------------------------------------------------
  # Detect duplicate headers in the mapping.
  #
  # Useful for import validation, e.g., if a CSV contains:
  #   ["name", "email", "email"]
  #
  # Returns:
  #   ["email"]
  #
  # --------------------------------------------------------------
  def duplicate_headers
    ordered_fields
      .group_by { |h| h }
      .select   { |_k, v| v.size > 1 }
      .keys
  end

  # --------------------------------------------------------------
  # Given an ActiveRecord instance, extract values in the order needed
  # for CSV export.
  #
  # Example:
  #   ordered_fields = ["email", "first_name"]
  #   record.email      → "bob@example.com"
  #   record.first_name → "Bob"
  #
  # Output:
  #   ["bob@example.com", "Bob"]
  #
  # --------------------------------------------------------------
  def values_for(record)
    ordered_fields.map { |f| record.public_send(f) }
  end

  # --------------------------------------------------------------
  # Convert mapping to a JSON-friendly structure.
  #
  # Used by APIs or import UI to remember mapping preferences.
  #
  # Example output:
  #   {
  #     model_class: "User",
  #     ordered_fields: ["email", "first_name"]
  #   }
  # --------------------------------------------------------------
  def to_h
    {
      model_class: model_class.name,
      ordered_fields: ordered_fields
    }
  end
end
