# frozen_string_literal: true

require 'csv'
require_relative 'field_mapping'
require_relative 'duplicate_action'

# Always use ChangeOffendingFieldAction unless replaced later.
DEFAULT_DUPLICATE_ACTION = ChangeOffendingFieldAction.new

class Import
  def initialize(klass:, file:, mapping: nil, dup_action: nil)
    @klass = klass
    @file = file
    @mapping = mapping
    @duplicate_action = dup_action || DEFAULT_DUPLICATE_ACTION
  end

  # --------------------------------------------------------------
  # MAIN IMPORT PROCESS
  # --------------------------------------------------------------
  def perform
    mapping = @mapping || default_mapping(@klass)

    rows = parse_csv(@file, mapping)
    duplicate_groups = []
    successful_inserts = 0

    ActiveRecord::Base.transaction do
      rows.each do |attrs|
        begin
          obj = @klass.new(attrs)
          obj.save!
          successful_inserts += 1

        rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
          duplicate_groups << normalize_duplicate(attrs)
        end
      end

      process_duplicates(@klass, duplicate_groups)
    end

    {
      imported: successful_inserts,
      duplicates: duplicate_groups.length
    }
  end

  private

  # --------------------------------------------------------------
  # DUPLICATE PROCESSING
  # --------------------------------------------------------------
  def normalize_duplicate(incoming_hash)
    pk = @klass.primary_key.to_sym
    existing = @klass.find_by(pk => incoming_hash[pk])

    [
      existing&.attributes&.symbolize_keys || {},
      incoming_hash.symbolize_keys
    ]
  end

  def process_duplicates(klass, groups)
    groups.each do |records|
      processed = @duplicate_action.on_duplicate_record(
        klass: klass,
        records: records
      )

      next if processed.nil?

      processed.each do |attrs|
        klass.create!(attrs)
      end
    end
  end

  # --------------------------------------------------------------
  # MAPPING
  # --------------------------------------------------------------
  def default_mapping(klass)
    FieldMapping.new(klass, klass.internal_and_external_fields)
  end

  # --------------------------------------------------------------
  # CSV PARSING
  # --------------------------------------------------------------
  def parse_csv(file, mapping)
    fields = mapping.ordered_fields
    rows = []

    CSV.foreach(file, headers: false) do |row|
      rows << Hash[fields.zip(row)]
    end

    rows
  end
end
