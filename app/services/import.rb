# frozen_string_literal: true

require 'csv'

# By default, if the caller does not specify a duplicate action,
# we use ChangeOffendingFieldAction. This ensures the importer
# always has a duplicate-resolution strategy.
DEFAULT_DUPLICATE_ACTION = ChangeOffendingFieldAction.new

##
# Import class
#
# This class handles end-to-end CSV importing for any model that includes
# the ImportableExportable mixin. Its responsibilities include:
#
#   • Loading CSV data
#   • Mapping CSV columns into model attributes
#   • Attempting to save each record
#   • Collecting duplicate rows
#   • Handling duplicates through a DuplicateAction strategy object
#
# The importer does NOT save the duplicates immediately. Instead it delegates
# conflict resolution to DuplicateAction subclasses.
#
class Import
  ##
  # Initializes an Import instance
  #
  # @param klass [Class] ActiveRecord model to import into
  # @param file [String] path to CSV file
  # @param mapping [FieldMapping, nil] optional mapping override
  # @param dup_action [DuplicateAction, nil] optional duplicate handler override
  #
  def initialize(klass:, file:, headers: nil, dup_action: nil)
    @klass = klass
    @file = file
    @headers = headers
    @duplicate_action = dup_action || DEFAULT_DUPLICATE_ACTION
  end

  # --------------------------------------------------------------
  # MAIN IMPORT PROCESS
  # --------------------------------------------------------------

  ##
  # Runs the full import:
  #   1. Builds or uses existing field mapping
  #   2. Parses the CSV into attribute hashes
  #   3. Attempts to insert each row
  #   4. On failure, collects duplicates into groups
  #   5. Processes duplicate groups with assigned DuplicateAction
  #
  # Returns a summary with :imported and :duplicates count
  #
  def perform(use_headers)
    duplicate_groups = []   # Will hold duplicate row sets
    successful_inserts = 0  # Counter for successful saves

    # Call the model-level importer (defined in each model using the import mixin)
    dups = @klass.try_import_records(
      @file,
      @headers,
      use_headers
    )

    dups.each {|dup| duplicate_groups << normalize_duplicate(dup)}


    # Let the duplicate action process all collected conflicts
    process_duplicates(@klass, duplicate_groups)


    # Return summary of import results
    {
      imported: successful_inserts,
      duplicates: duplicate_groups.length
    }
  end

  private

  # --------------------------------------------------------------
  # DUPLICATE PROCESSING
  # --------------------------------------------------------------

  ##
  # Normalizes duplicate information into a two-element array:
  #
  #   [ existing_record_hash, incoming_record_hash ]
  #
  # Where:
  #   • existing_record_hash may be {} if not found in DB
  #   • incoming_record_hash is always the failed attributes
  #
  # This format is used by DuplicateAction subclasses to determine
  # how the conflict should be resolved.
  #
  def normalize_duplicate(incoming_obj)
    # Try to find the existing record using the primary key value
    field = find_offending_field(incoming_obj)

    value = {}
    value[field] = incoming_obj.as_json()[field.to_s]

    existing = @klass.find_by(value)
    {
      existing: existing,  # Existing row (maybe empty)
      incoming: incoming_obj                # Incoming row
    }
  end

  def find_offending_field(incoming_obj)
    incoming_obj.validate
    incoming_obj.errors.details.each do |attribute, error_details_array|
      return attribute if error_details_array.any? { |detail_hash| detail_hash[:error] == :taken }
    end
  end

  ##
  # For every duplicate group (existing, incoming), call the provided duplicate
  # action strategy. If the strategy returns an array of cleaned/merged rows,
  # reinsert them into the DB.
  #
  # A duplicate action is expected to implement:
  #
  #     on_duplicate_record(klass:, records:)
  #
  def process_duplicates(klass, groups)
    groups.each do |records|
      processed = @duplicate_action.on_duplicate_record(
         klass,
         records
      )

      # If the duplicate action returns nil, it means “skip insertion”
      next if processed.nil?

      processed.save!
    end
  end

end
