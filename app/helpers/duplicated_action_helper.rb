# frozen_string_literal: true

# ===============================================================
# DuplicateAction (ABSTRACT MIXIN)
#
# All duplicate-resolution strategies used during import must include
# this module and implement:
#
#   on_duplicate_record(klass:, records:)
#
# Parameters:
#   klass    => ActiveRecord model affected
#   records  => Array of hashes or model objects representing conflicts
#
# Return:
#   - nil                 → skip inserting record
#   - Array<Hash>         → rows to (re)insert
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
# Simply skips the offending row. Nothing is inserted.
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
# Takes all conflicting rows and merges them. Later values override earlier ones.
# Result:
#   One fully merged record replacing the original.
# ===============================================================
class UpdateExistingRecordAction
  include DuplicateAction

  def on_duplicate_record(klass:, records:)
    merged = {}

    # Accept both Hashes and ActiveRecord objects
    records.each do |rec|
      row = rec.is_a?(Hash) ? rec : rec.attributes.symbolize_keys
      row.each do |key, value|
        merged[key] = value unless value.nil?
      end
    end

    [merged]  # Return exactly one merged record
  end
end

# ===============================================================
# ChangeOffendingFieldAction
#
# Autoresolves uniqueness violations by modifying unique fields.
# Example:
#   existing: { name: "Alice" }
#   incoming: { name: "Alice" }
#
# Becomes:
#   { name: "Alice_copy" }
#
# If still not unique:
#   { name: "Alice_copy2" }
#
# ===============================================================
class ChangeOffendingFieldAction
  include DuplicateAction

  def on_duplicate_record(klass:, records:)
    existing = normalize(records.first)
    incoming = normalize(records.last).dup

    unique_fields = unique_constraint_fields(klass)

    unique_fields.each do |field|
      next unless incoming[field] == existing[field]

      incoming[field] =
        generate_unique_value(
          klass: klass,
          field: field,
          base: incoming[field]
        )
    end

    [incoming]
  end

  private

  # Accept ActiveRecord or hash
  def normalize(record)
    return record.symbolize_keys if record.is_a?(Hash)
    record.attributes.symbolize_keys
  end

  # Use AR validators to detect which fields are unique
  def unique_constraint_fields(klass)
    klass.validators
         .select { |v| v.is_a?(ActiveRecord::Validations::UniquenessValidator) }
         .flat_map(&:attributes)
         .map(&:to_sym)
  end

  # Increment until unique in DB
  def generate_unique_value(klass:, field:, base:)
    candidate = base.to_s
    counter = 1

    while klass.exists?(field => candidate)
      candidate = "#{base}_copy#{counter == 1 ? '' : counter}"
      counter += 1
    end

    candidate
  end
end
