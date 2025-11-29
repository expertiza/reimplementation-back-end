# This file defines a helper module for handling duplicate record events.
# It is backwards-compatible with the previous interface while also
# providing a full class-based DuplicateAction architecture.
module DuplicatedActionHelper
  ###############################################
  # PUBLIC METHOD (Existing API)
  ###############################################
  # Processes duplicated actions using the legacy string-based API
  # OR the new class-based DuplicateAction actions.
  #
  # @param action [String, DuplicateAction] the action to perform
  # @param data [Array<Hash>] duplicated data entries
  # @return [Array<Hash>] result after applying the action
  def process_duplicated_action(action, data)
    case action
    when 'merge'
      merge_duplicated_data(data)

    when 'delete'
      delete_duplicated_data(data)

      # NEW: Allow passing in an object that implements DuplicateAction
    when DuplicateAction
      record = OpenStruct.new(data.first) # Adapts hash input to object-like behavior
      klass  = OpenStruct # For non-ActiveRecord duplicate workflows
      resolved = action.on_duplicate_record(klass: klass, record: record)
      resolved ? [resolved.to_h] : []

    else
      raise ArgumentError, "Unknown action: #{action}"
    end
  end

  ###############################################
  # EXISTING PRIVATE METHODS (unchanged behavior)
  ###############################################
  private
  # Merges duplicated data entries into a single entry.
  #
  # @param data [Array<Hash>]
  # @return [Array<Hash>]
  def merge_duplicated_data(data)
    data.uniq { |entry| entry[:id] }
  end

  # Deletes duplicated data entries.
  #
  # @param data [Array<Hash>]
  # @return [Array<Hash>]
  def delete_duplicated_data(data)
    []
  end

  ###############################################
  # NEW — DUPLICATE ACTION SYSTEM
  ###############################################
  module DuplicateAction
    # Abstract method that all actions must implement.
    def on_duplicate_record(klass:, record:)
      raise NotImplementedError,
            "on_duplicate_record must be implemented in #{self.class.name}"
    end

    private

    # Offending fields for systems using uniqueness attributes.
    # For simple hash-based data, this defaults to [:id].
    def offending_fields_for(_klass, record)
      record.to_h.keys.select { |k| k.to_s.include?("id") }
    end
  end

  ###############################################
  # NEW ACTION CLASS: SkipRecord
  ###############################################
  class SkipRecord
    include DuplicateAction

    def on_duplicate_record(klass:, record:)
      Rails.logger.info("Skipping duplicate record: #{record.to_h}")
      nil
    end
  end

  ###############################################
  # NEW ACTION CLASS: ChangeField (“_copy” resolver)
  ###############################################
  class ChangeField
    include DuplicateAction

    MAX_ATTEMPTS = 10

    def on_duplicate_record(klass:, record:)
      fields = offending_fields_for(klass, record)
      return nil if fields.empty?

      updated = record.dup
      attempts = 0

      while attempts < MAX_ATTEMPTS
        fields.each do |f|
          value = updated.send(f)
          updated.send("#{f}=", "#{value}_copy")
        end

        # For simple usage (hash input), assume "copy" resolves duplicates
        return updated unless updated.to_h.values.any?(&:nil?)

        attempts += 1
      end

      Rails.logger.warn("Could not resolve duplicate after #{MAX_ATTEMPTS} attempts")
      nil
    end
  end

  ###############################################
  # NEW ACTION CLASS: UpdateExistingRecord
  ###############################################
  class UpdateExistingRecord
    include DuplicateAction

    def on_duplicate_record(klass:, record:)
      # For hash-based workflows, just return the provided record
      # (Existing record is "updated" logically)
      record
    end
  end

end