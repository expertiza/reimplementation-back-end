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
  def on_duplicate_record(klass, records)
    # Normalize both existing and incoming row formats
    existing = records[:existing]
    incoming = records[:incoming].dup

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

    incoming  # Returning one resolved record
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
