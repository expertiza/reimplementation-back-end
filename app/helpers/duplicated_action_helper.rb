# frozen_string_literal: true

# ===============================================================
# DuplicateAction (ABSTRACT MIXIN)
#
# All duplicate-resolution strategies used by Import must include
# this module. It defines a single required method:
#
#   on_duplicate_record(klass:, records:)
#
# Arguments:
#   klass:    The ActiveRecord model being imported (e.g., Team, User)
#   records:  An Array containing two elements:
#               [ existing_record_hash, incoming_record_hash ]
#             Both may be:
#               - Hashes (symbolized)
#               - ActiveRecord instances
#
# Return value expectations:
#   nil               → indicates the duplicate should not be inserted
#   Array<Hash>       → 1 or more hashes representing records to create
#
#   The Import class will call klass.create!(hash) for each returned hash.
#
# ===============================================================
module DuplicateAction
  def on_duplicate_record(klass:, records:)
    raise NotImplementedError,
          "#{self.class} must implement `on_duplicate_record`"
  end
end


# ===============================================================
# SkipRecordAction
#
# Strategy: **Ignore the incoming row entirely.**
#
# Usage example:
#   - User chooses "Skip duplicates" on import
#   - Any row that violates uniqueness constraints is dropped
#
# Behavior:
#   Returning `nil` instructs Import.perform to do nothing.
# ===============================================================
class SkipRecordAction
  include DuplicateAction

  def on_duplicate_record(klass:, records:)
    nil
  end
end


# ===============================================================
# UpdateExistingRecordAction
#
# Strategy: **Merge all duplicates into a single updated record.**
#
# Meaning:
#   - If both existing and incoming records have data,
#     incoming values overwrite existing ones (unless nil).
#
# Example:
#   existing = { id: 5, name: "Alice", score: 80 }
#   incoming = { id: 5, name: "Alice B.", score: nil }
#
#   result   = { id: 5, name: "Alice B.", score: 80 }
#
# Use case:
#   "Update existing records with imported values"
#
# Importer will delete the original conflicting record and replace it
# with the merged one.
# ===============================================================
class UpdateExistingRecordAction
  include DuplicateAction

  def on_duplicate_record(klass:, records:)
    merged = {}

    records.each do |rec|
      # Accept Hashes OR ActiveRecord instances
      row = rec.is_a?(Hash) ? rec : rec.attributes.symbolize_keys

      # Merge:
      # Later values override earlier ones unless nil
      row.each do |key, value|
        merged[key] = value unless value.nil?
      end
    end

    # Return one record to create
    [merged]
  end
end


# ===============================================================
# ChangeOffendingFieldAction
#
# Strategy: **Automatically adjust the offending (unique) fields**
# so the imported row can still be inserted.
#
# This is the default strategy used by Import unless overridden.
#
# Example:
#   existing.name = "Alice"
#   incoming.name = "Alice"
#
# → incoming.name becomes "Alice_copy"
#
# If still not unique:
#   "Alice_copy2", "Alice_copy3", etc.
#
# How it works:
#   1. Collect all fields with uniqueness validators
#   2. If incoming[field] == existing[field], mutate it
#   3. Keep incrementing until the value no longer exists in the DB
#
# ===============================================================
class ChangeOffendingFieldAction
  include DuplicateAction

  def on_duplicate_record(klass:, records:)
    # Normalize both existing and incoming row formats
    existing = normalize(records.first)
    incoming = normalize(records.last).dup

    # Determine fields with uniqueness validators
    unique_fields = unique_constraint_fields(klass)

    # For each unique field, adjust if conflict detected
    unique_fields.each do |field|
      next unless incoming[field] == existing[field]

      incoming[field] = generate_unique_value(
        klass: klass,
        field: field,
        base: incoming[field]
      )
    end

    [incoming]  # Returning one resolved record
  end

  private

  # Standardize input into a symbolized hash
  def normalize(record)
    return record.symbolize_keys if record.is_a?(Hash)
    record.attributes.symbolize_keys
  end

  # Extract all attributes validated as unique via ActiveRecord
  def unique_constraint_fields(klass)
    klass.validators
         .select { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
         .flat_map(&:attributes)
         .map(&:to_sym)
  end

  # Generate a new unique value by appending suffixes until unique
  #
  # Example:
  #   base = "Alice"
  #   → "Alice_copy"
  #   → "Alice_copy2"
  #   → "Alice_copy3"
  #
  def generate_unique_value(klass:, field:, base:)
    candidate = base.to_s
    counter = 1

    # Keep generating values until one does not exist in DB
    while klass.exists?(field => candidate)
      candidate =
        "#{base}_copy#{counter == 1 ? '' : counter}"

      counter += 1
    end

    candidate
  end
end
