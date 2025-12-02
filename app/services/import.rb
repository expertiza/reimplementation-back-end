# frozen_string_literal: true

require 'csv'
require_relative 'field_mapping'
require_relative 'duplicate_action'

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
  def initialize(klass:, file:, mapping: nil, dup_action: nil)
    @klass = klass
    @file = file
    @mapping = mapping
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
  def perform
    # Use provided mapping or fall back to default derived from model
    mapping = @mapping || default_mapping(@klass)

    # Convert CSV rows into attribute hashes using the field mapping
    rows = parse_csv(@file, mapping)

    duplicate_groups = []   # Will hold duplicate row sets
    successful_inserts = 0  # Counter for successful saves

    # Wrap everything in a transaction to ensure consistency
    ActiveRecord::Base.transaction do
      rows.each do |attrs|
        begin
          # Attempt to create the record
          obj = @klass.new(attrs)
          obj.save!
          successful_inserts += 1

        rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
          # Any uniqueness or validation failure is treated as a duplicate
          duplicate_groups << normalize_duplicate(attrs)
        end
      end

      # Let the duplicate action process all collected conflicts
      process_duplicates(@klass, duplicate_groups)
    end

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
  def normalize_duplicate(incoming_hash)
    pk = @klass.primary_key.to_sym

    # Try to find the existing record using the primary key value
    existing = @klass.find_by(pk => incoming_hash[pk])

    [
      existing&.attributes&.symbolize_keys || {},  # Existing row (maybe empty)
      incoming_hash.symbolize_keys                 # Incoming row
    ]
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
        klass: klass,
        records: records
      )

      # If the duplicate action returns nil, it means “skip insertion”
      next if processed.nil?

      # Otherwise, treat each returned hash as a new valid record
      processed.each do |attrs|
        klass.create!(attrs)
      end
    end
  end

  # --------------------------------------------------------------
  # MAPPING
  # --------------------------------------------------------------

  ##
  # Generates a default field mapping using all internal and external fields
  # exposed by the model. This ensures every column that CAN be imported
  # will be imported.
  #
  def default_mapping(klass)
    FieldMapping.new(klass, klass.internal_and_external_fields)
  end

  # --------------------------------------------------------------
  # CSV PARSING
  # --------------------------------------------------------------

  ##
  # Reads the CSV and builds an array of attribute hashes:
  #
  #   [ {field1: val1, field2: val2, ...}, ... ]
  #
  # The mapping determines which fields correspond to which columns.
  #
  def parse_csv(file, mapping)
    fields = mapping.ordered_fields
    rows = []

    # No headers — CSV columns must follow mapping order precisely.
    CSV.foreach(file, headers: false) do |row|
      rows << Hash[fields.zip(row)]
    end

    rows
  end
end
