# importable_exportable_helper.rb
#
# ===============================================================
# ExternalClass
#
# Represents a class referenced by another class during import.
# For example:
#   - Importing Teams may also need to create Users or Roles
#   - Importing Assignments may need to create Topics
#
# This object encodes:
#   • Which class is referenced
#   • Whether it should be LOOKED UP or CREATED
#   • What field should be used to perform lookups
#
# The importer uses this information to:
#   • Map CSV fields to the external class
#   • Attempt to find existing referenced objects
#   • Create new referenced objects when required
#
# Example:
#   ExternalClass.new(User, should_lookup: true, should_create: false, lookup_field: :email)
# ===============================================================
class ExternalClass
  attr_accessor :ref_class, :should_lookup, :should_create

  def initialize(ref_class, should_lookup = false, should_create = true, lookup_field = nil)
    @ref_class     = ref_class      # The class being referenced (e.g., User)
    @should_lookup = should_lookup  # Whether existing objects should be searched for
    @should_create = should_create  # Whether new objects should be created if no match found
    @lookup_field  = lookup_field   # Column used to identify existing objects
  end

  # --------------------------------------------------------------
  # Resolve what fields belong to the external class.
  #
  # If the class itself includes ImportableExportable, we use its
  # internal_fields. Otherwise, we fall back to:
  #   - the lookup field, or
  #   - the primary key
  #
  # All returned fields are namespaced (role_name, user_email, etc.)
  # --------------------------------------------------------------
  def fields
    if @ref_class.respond_to?(:internal_fields)
      @ref_class.internal_fields.map { |field| self.class.append_class_name(@ref_class, field) }
    else
      [self.class.append_class_name(@ref_class, @lookup_field.to_s), self.class.append_class_name(@ref_class, @ref_class.primary_key)]
    end
  end

  # --------------------------------------------------------------
  # Lookup an external object in the database.
  #
  # Uses either:
  #   • a lookup field, or
  #   • the primary key
  #
  # It will try both the namespaced version (e.g. role_name)
  # and the raw version (name) depending on what exists in the model.
  # --------------------------------------------------------------
  def lookup(class_values)
    class_name_lookup_field  = self.class.append_class_name(@ref_class, @lookup_field.to_s)
    class_name_primary_field = self.class.append_class_name(@ref_class, @ref_class.primary_key)

    value = nil

    # ---------- Try lookup field ----------
    if @lookup_field && class_values[class_name_lookup_field]
      if @ref_class.attribute_method?(@lookup_field)
        value = @ref_class.find_by(@lookup_field => class_values[class_name_lookup_field])
      elsif @ref_class.attribute_method?(class_name_lookup_field)
        value = @ref_class.find_by(class_name_lookup_field => class_values[class_name_lookup_field])
      end

      # ---------- Try primary key ----------
    elsif class_values[class_name_primary_field]
      if @ref_class.attribute_method?(@ref_class.primary_key)
        value = @ref_class.find_by(@ref_class.primary_key => class_values[class_name_primary_field])
      elsif @ref_class.attribute_method?(class_name_primary_field)
        value = @ref_class.find_by(class_name_primary_field => class_values[class_name_primary_field])
      end
    end

    value
  end

  # --------------------------------------------------------------
  # Convert CSV attributes (namespaced) into attributes that match
  # the external class (un-namespaced).
  # --------------------------------------------------------------
  def from_hash(attrs)
    fixed = {}
    attrs.each { |k, v| fixed[self.class.unappended_class_name(@ref_class, k)] = v }
    @ref_class.new(fixed)
  end

  # Prefix column with the class name ("role_name", "user_email")
  def self.append_class_name(ref_class, field)
    "#{ref_class.name.underscore}_#{field}"
  end

  # Remove class name prefix
  def self.unappended_class_name(ref_class, name)
    name.delete_prefix("#{ref_class.name.underscore}_")
  end
end

# ===============================================================
# ImportableExportableHelper
#
# This module adds import/export metadata and behavior to models.
#
# It supports:
#   • mandatory fields
#   • optional fields
#   • external class definitions
#   • combining internal and external fields
#   • row-level import logic
#
# Any model including this module becomes import/export capable.
#
# Example:
#
#   class Team < ApplicationRecord
#     extend ImportableExportableHelper
#     mandatory_fields :name
#     external_classes ExternalClass.new(User, true, true, :email)
#   end
#
# ===============================================================
module ImportableExportableHelper
  attr_accessor :available_actions_on_duplicate

  # --------------------------------------------------------------
  # When extended by a class, inherit parent import settings.
  #
  # This allows STI or subclassed models to reuse configuration.
  # --------------------------------------------------------------
  def self.extended(base)
    if base.superclass.respond_to?(:mandatory_fields)
      base.instance_variable_set(:@mandatory_fields, base.superclass.mandatory_fields)
      base.instance_variable_set(:@external_classes, base.superclass.external_classes)
      base.instance_variable_set(:@class_name, base.superclass.name)
      base.instance_variable_set(:@available_actions_on_duplicate, base.superclass.available_actions_on_duplicate)
    else
      base.instance_variable_set(:@class_name, base.name)
    end
  end

  # --------------------------------------------------------------
  # Define or retrieve mandatory fields.
  # These must be present in the CSV.
  # --------------------------------------------------------------
  def mandatory_fields(*fields)
    if fields.any?
      @mandatory_fields = fields.map(&:to_s)
    else
      @mandatory_fields
    end
  end

  # --------------------------------------------------------------
  # Optional = internal fields - mandatory
  # --------------------------------------------------------------
  def optional_fields
    internal_fields - mandatory_fields
  end

  # --------------------------------------------------------------
  # Define or retrieve external classes.
  #
  # Example:
  #   external_classes ExternalClass.new(Role, true, false, :name)
  # --------------------------------------------------------------
  def external_classes(*fields)
    if fields.any?
      @external_classes = fields
    else
      @external_classes
    end
  end

  # --------------------------------------------------------------
  # INTERNAL FIELDS
  #
  # Internal fields come from:
  #   • database column names
  #   • mandatory_fields
  #
  # Then external fields are removed (to prevent duplication).
  # --------------------------------------------------------------
  def internal_fields
    (column_names + (mandatory_fields || [])).uniq - external_fields
  end

  # --------------------------------------------------------------
  # EXTERNAL FIELDS
  #
  # Flatten all internal fields from all external class definitions.
  # --------------------------------------------------------------
  def external_fields
    fields = []
    external_classes&.each { |external_class| fields += external_class.fields }

    fields
  end

  # Combined fields for full CSV mapping
  def internal_and_external_fields
    internal_fields + external_fields
  end

  # --------------------------------------------------------------
  # Construct an object from a CSV row hash.
  #
  # For internal fields, the value is stored as an array during
  # parsing, so we take the first element.
  # --------------------------------------------------------------
  def from_hash(attrs)
    cleaned = {}
    attrs.each { |k, v| cleaned[k] = v[0] }
    new(cleaned)
  end

  # --------------------------------------------------------------
  # Export helper
  # Returns a hash of internal fields → values
  # --------------------------------------------------------------
  def to_hash(fields = self.class.internal_fields)
    fields.to_h { |f| [f, send(f)] }
  end


  # --------------------------------------------------------------
  # MAIN IMPORT WORKFLOW
  #
  # Creates a temporary file with normalized headers,
  # then iterates through rows, importing them one by one.
  #
  # Duplicate objects are collected and returned.
  # --------------------------------------------------------------
  def try_import_records(file, headers, use_header: false)
    temp_file = 'output.csv'
    csv_file = CSV.read(file)

    # ---- Normalize header row ----
    CSV.open(temp_file, "w") do |csv|
      if use_header
        headers = csv_file.shift.map { |h| h.parameterize.underscore }
      else
        headers = headers.map { |header| header.parameterize.underscore }
      end

      csv << headers
      csv_file.each { |row| csv << row }
    end

    temp_contents = CSV.read(temp_file)
    temp_contents.shift  # drop header

    duplicate_records = []

    ActiveRecord::Base.transaction do
      temp_contents.each do |row|
        dup = import_row(row, temp_file)
        duplicate_records << dup if dup && dup != true
      end

      # Keep duplicates for UI, roll back DB changes
      # raise ActiveRecord::Rollback
    end

    File.delete(temp_file)
    duplicate_records
  end

  # --------------------------------------------------------------
  # Import a single row into the current model.
  #
  # Handles:
  #   • mapping values
  #   • building internal object
  #   • external object lookup/creation
  #   • save + duplicate capture
  #
  # Returns:
  #   • true if saved successfully
  #   • duplicate object if duplicate occurred
  # --------------------------------------------------------------
  def import_row(row, file)
    header_row = CSV.open(file, &:first)
    mapping = FieldMapping.from_header(self, header_row)

    # Build row_hash where each key maps to all found values
    row_hash = {}
    mapping.ordered_fields.zip(row).each do |key, value|
      row_hash[key] ||= []
      row_hash[key] << value
    end

    puts "Row Hash: #{row_hash}"

    # Create object for this class
    current_class_attrs = row_hash.slice(*internal_fields)
    created_object = from_hash(current_class_attrs)

    # for each external class, try to look them up
    external_classes&.each do |external_class|
      lookup_external_class(row_hash, external_class, created_object)
    end

    duplicate = save_object(created_object)
    return duplicate if duplicate && duplicate != true

    return unless external_classes

    external_classes.each do |external_class|
      create_external_class(row_hash, external_class, created_object)
    end

  end

  private

  # --------------------------------------------------------------
  # Attempt to find an external object via lookup rules.
  # If found, attach it to the parent object.
  # --------------------------------------------------------------
  def lookup_external_class(row_hash, external_class, parent_obj)
    if external_class.should_lookup && (found = external_class.lookup(row_hash))
      parent_obj.send("#{external_class.ref_class.name.downcase}=", found)
      nil
    end
  end

  # --------------------------------------------------------------
  # When lookups fail AND the external class allows creation,
  # build and save new external objects.
  #
  # Handles multi-row data such as:
  #   field1: ["A", "B"]
  #   field2: ["X", "Y"]
  #
  # Which turns into:
  #   [{field1: "A", field2: "X"}, {field1: "B", field2: "Y"}]
  # --------------------------------------------------------------
  def create_external_class(row_hash, external_class, parent_obj)
    return unless external_class.should_create

    current_class_attrs = row_hash.slice(*external_class.internal_fields)

    object_sets = current_class_attrs.values.transpose
    object_sets_with_keys = object_sets.map do |row_values|
      Hash[current_class_attrs.keys.zip(row_values)]
    end

    object_sets_with_keys.each do |attrs|
      created_object = external_class.from_hash(attrs)

      # Set relationship to parent
      created_object.send("#{@class_name.underscore}=", parent_obj)

      save_object(created_object)
    end
  end

  # --------------------------------------------------------------
  # Save an object safely, detecting:
  #   • Validation errors
  #   • Uniqueness violations
  #
  # Returns:
  #   • created_object on uniqueness error (for duplicate workflow)
  #   • true if saved
  # --------------------------------------------------------------
  def save_object(created_object)
    created_object.save!
  rescue ActiveRecord::RecordInvalid => e
    # Check if a specific attribute has a :uniqueness error
    puts "Validation error: #{e.message}"

    unless created_object.errors.details[:attribute_name].any? { |detail| detail[:error] == :uniqueness }
      raise StandardError.new(e.message)
    end

    puts 'Uniqueness violation on attribute_name!'
    created_object
  rescue ActiveRecord::RecordNotUnique => e
    puts "Unique constraint violation: #{e.message}"
    created_object
  end
end
