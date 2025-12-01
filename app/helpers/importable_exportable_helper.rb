# importable_exportable_helper.rb

# Class for combining external class information. Keeps track of whether this class should have
# its information looked up or saved. Assumes that information should be created when initialized
class ExternalClass
  attr_accessor :ref_class, :should_lookup, :should_create

  def initialize(ref_class, should_lookup = false, should_create = true, lookup_field = nil)
    @ref_class = ref_class
    @should_lookup = should_lookup
    @should_create = should_create
    @lookup_field = lookup_field
  end

  # If the ref class has the ImportableExportable Mixin, refer to that version of the import export fields func.
  # If it doessn't, return the lookup field (or the primary key)
  def internal_fields
    if @ref_class.respond_to?(:internal_fields)
      @ref_class.internal_fields.map {|field| append_class_name(field)}
    else
      [append_class_name(@lookup_field.to_s), append_class_name(@ref_class.primary_key)]
    end

  end


  # Attempts too look in the database for any mention of the current class. It looks using the
  # given lookup field and the primary key. It checks both with and without the classname appended
  # to the front
  def lookup(class_values)
    # See if lookup field or primary key is in values hash. If not, return nothing
    # puts "starting lookup"
    class_name_lookup_field = append_class_name(@lookup_field.to_s)
    class_name_primary_key = append_class_name(@ref_class.primary_key)
    if @lookup_field && class_values[class_name_lookup_field]
      # puts @lookup_field
      # Ex. field: name,        value: class_values[role_name]
      if @ref_class.attribute_method?(@lookup_field)
        value = @ref_class.find_by(@lookup_field => class_values[class_name_lookup_field])
      # puts "lookup field: #{value}"
      # Ex. field: role_name,   value: class_values[role_name]
      elsif @ref_class.attribute_method?(class_name_lookup_field)
        value ||= @ref_class.find_by(class_name_lookup_field => class_values[class_name_lookup_field])
        # puts "append class name? #{value}"
      end

    elsif class_values[class_name_primary_key]
      # Ex. field: id,          value: class_values[role_id]
      if @ref_class.attribute_method?(@ref_class.primary_key)
        value ||= @ref_class.find_by(@ref_class.primary_key => class_values[class_name_primary_key])
      # puts "primary key: #{value}"
      # Ex. field: role_id      value: class_values[role_id]
      elsif @ref_class.attribute_method?(class_name_primary_key)
        value ||= @ref_class.find_by(class_name_primary_key => class_values[class_name_primary_key])
        # puts "pk with class name: #{value}"
      end
    end

    value
  end

  def from_hash(attrs)
    fixed_attrs = {}
    attrs.each {|k, v| fixed_attrs[unappended_class_name(k)] = v}

    @ref_class.new(fixed_attrs)
  end

  private

  # Method to add the class name to a field. This is useful when the CSV might refer to a column with
  # the class name appended (Ex role_name) but the internal field drops the class name (Ex Role.name)
  def append_class_name(field)
    "#{@ref_class.name.underscore}_#{field}"
  end

  def unappended_class_name(name)
    name.delete_prefix("#{@ref_class.name.underscore}_")
  end
end

module ImportableExportableHelper
  attr_accessor :available_actions_on_duplicate

  # def self.included(base)
  #   base.extend(ClassMethods)
  # end

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

  # module ClassMethods

  def mandatory_fields(*fields)
    if fields.any?
      @mandatory_fields = fields.map(&:to_s)
    else
      @mandatory_fields
    end
  end

  def optional_fields
    internal_fields - mandatory_fields
  end

  def external_classes(*fields)
    if fields.any?
      @external_classes = fields
    else
      @external_classes
    end
  end


  # use the column names and mandaroty fields to know which fields constitute
  # internal fields. This is becuase of cases such as the password of a user being
  # the password_digest column in the database, but we need to assign it to the
  # password field of the object.
  def internal_fields
    (column_names + (mandatory_fields || [])).uniq - external_fields
  end

  def external_fields
    fields = []
    external_classes&.each { |external_class| fields += external_class.internal_fields }

    fields
  end

  def internal_and_external_fields
    internal_fields + external_fields
  end

  # Factory method for importing a record from a hash
  def from_hash(attrs)
    fixed_attrs = {}
    attrs.each {|k, v| fixed_attrs[k] = v[0]}

    new(fixed_attrs)
  end

  # Instance method to serialize a record for export
  def to_hash(fields = self.class.internal_fields)
    fields.to_h { |f| [f, send(f)] }
  end

  # todo - possibly extract this function to the service
  def try_import_records(file, headers, use_header: false)
    temp_file = 'output.csv'
    csv_file = CSV.read(file)

    # In a temp file, so that headers can be added to the top if the use_header options isn't selected
    CSV.open(temp_file, 'w') do |csv|

      if use_header
        headers = csv_file[0].map { |header| header.parameterize.underscore }
        csv_file.shift
      else
        headers = headers.map { |header| header.parameterize.underscore }
      end

      csv << headers

      # then copy the rest of the csv file
      csv_file.each do |row|
        csv << row
      end
    end

    temp_contents = CSV.read(temp_file)
    temp_contents.shift

    dup_records = []

    ActiveRecord::Base.transaction do
      temp_contents.each do |row|
        # Get the row as a hash, with the header pointing towards the attribute value
        dup_obj = import_row(row,  temp_file)
        dup_records << dup_obj if dup_obj && dup_obj != true
      end

      pp dup_records

      # todo - Handle duplicate records that are thrown out when importing the rows

      # Comment this out if you want to run the tests
      # raise ActiveRecord::Rollback # todo - remove this when wanting to actually channge the data
    end


    File.delete(temp_file)
    dup_records

  end

  # Import row function takes a hash for a row and tries to save it in the current class.
  # It takes a related class and object so that it can be used recursively. If a row should
  # update two classes,and one relies upon another, the recursion can be used to set the
  # belongs to relationship.
  # (EX if )
  def import_row(row, file)
    # Open the csv file, get the header row, and build the mapping with only the fields available in the current class
    header_row = CSV.open(file, &:first)
    mapping = FieldMapping.from_header(self, header_row) # Get mapping of only internal fields
    # pp row
    row_hash = {}
    mapping.ordered_fields.zip(row).each do |key, value|
      row_hash[key] ||= [] # Initialize an empty array if the key is new
      row_hash[key] << value
    end

    puts "Row Hash: #{row_hash}"

    current_class_attrs = row_hash.slice(*internal_fields)
    created_object = from_hash(current_class_attrs)

    # for each external class, try to look them up
    external_classes&.each do |external_class|
      lookup_external_class(row_hash, external_class, created_object)
    end

    dup_obj = save_object(created_object)

    return dup_obj if dup_obj && dup_obj != true

    # Then create external classes that rely on the object we just created

    return unless external_classes

    external_classes.each do |external_class|
      create_external_class(row_hash, external_class, created_object)
    end

  end

  private

  def lookup_external_class(row_hash, external_class, parent_obj)
    # Lookup - If the external class is marked as a lookup and a value is found
    if external_class.should_lookup && (lookup_value = external_class.lookup(row_hash))
      # Connect lookup value to the parent obj
      parent_obj.send("#{external_class.ref_class.name.downcase}=", lookup_value)
      nil
    end
  end

  def create_external_class(row_hash, external_class, parent_obj)
    # Create - If the external class is marked as a create, attempt to create a new obj and link to parents
    # This can happen if it is marked and a lookup val wasn't found
    return unless external_class.should_create

    # Get the attributes, with duplicates in an array
    current_class_attrs = row_hash.slice(*external_class.internal_fields)

    # In the order of the attributes, pair them together in new hashes. These new hashes
    # are ready to be made into the new object
    # Ex.
    # Initial: {"question_advice_score" => ["1", "2"],
    #           "question_advice_advice" => ["okay", "good"]}
    # Result:  [{"question_advice_score" => "1", "question_advice_advice" => "okay"},
    #           {"question_advice_score" => "2", "question_advice_advice" => "good"}]
    #
    object_sets = current_class_attrs.values.transpose
    object_sets_with_keys = object_sets.map do |row_values|
      Hash[current_class_attrs.keys.zip(row_values)]
    end


    # Use each set to create the new objects
    object_sets_with_keys.each do |attrs|
      created_object = external_class.from_hash(attrs)

      # link the newly created object and the parent both ways
      created_object.send("#{@class_name.underscore}=", parent_obj)
      # parent_obj.send("#{external_class.ref_class.name.underscore}=", created_object)

      save_object(created_object)
    end

  end

  def save_object(created_object)
    puts 'Create Obj:'
    pp created_object
    created_object.save!
  rescue ActiveRecord::RecordInvalid => e
    # Check if a specific attribute has a :uniqueness error
    unless created_object.errors.details[:attribute_name].any? { |detail| detail[:error] == :uniqueness }
      raise StandardError.new(e.message)
    end

    # Handle validation errors
    puts "Validation error: #{e.message}"

    puts 'Uniqueness violation on attribute_name!'
    created_object
  rescue ActiveRecord::RecordNotUnique => e
    # Handle unique constraint violations
    puts "Unique constraint violation: #{e.message}"
    created_object
  rescue StandardError => e
    raise e

  end


end
