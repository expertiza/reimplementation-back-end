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

  def on_duplicate_record(klass, records)
    merged = {}

    existing = records[:existing]

    klass.mandatory_fields.each do |field|
      value = {}
      value[field] = records[:incoming].send(field)
      existing.send(:assign_attributes, value)
    end

    existing
  end
end
