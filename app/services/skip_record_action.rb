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
  def on_duplicate_record(klass,
                          records)
    nil
  end
end
