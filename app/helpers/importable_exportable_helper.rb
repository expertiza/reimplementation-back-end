# importable_exportable_helper.rb
module ImportableExportableHelper
  attr_accessor :available_actions_on_duplicate
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :mandatory_fields, :optional_fields, :external_classes

    def mandatory_fields(*fields)
      if fields.any?
        @mandatory_fields = fields.map(&:to_s)
      else
        @mandatory_fields
      end
    end

    def optional_fields(*fields)
      if fields.any?
        @optional_fields = fields.map(&:to_s)
      else
        @optional_fields
      end
    end

    def external_classes(*fields)
      if fields.any?
        @external_classes = fields.map(&:to_s)
      else
        @external_classes
      end
    end

    def import_export_fields()
      (@mandatory_fields || []) + (@optional_fields || [])
    end

    # Factory method for importing a record from a hash
    def from_hash(attrs)
      new(attrs)
    end

    # todo - possibly extract this function to the service
    def try_import_records(file, headers, use_header: false)
      temp_file = 'output.csv'
      csv_file = CSV.open(file, headers: false)

      # In a temp file, so that headers can be added to the top if the use_header options isn't selected
      CSV.open(temp_file, "w") do |csv|
        unless use_header
          csv << headers
        end

        # then copy the rest of the csv file
        csv_file.each() do |row|
          csv << row
        end
      end

      CSV.foreach(temp_file) do |row|
        # Get the row as a hash, with the header pointing towards the attribute value
        import_row(row,  temp_file)
        # pp row
      end

      File.delete(temp_file)
    end

    # Import row function takes a hash for a row and tries to save it in the current class.
    # It takes a related class and object so that it can be used recursively. If a row should
    # update two classes,and one relies upon another, the recurison can be used to set the
    # belongs torelationship.
    # (EX if )
    def import_row(row, file, related_class: nil, related_obj: nil)
      # Open the csv file, get the header row, and build the mapping with only the fields available in the current class
      header_row = CSV.open(file, &:first)
      mapping = FieldMapping.from_header(self, header_row)

      # For internal fields, get the attributes and save a new version of the class
      row_hash = Hash[mapping.ordered_fields.zip(row)]
      attrs = row_hash.slice(*self.import_export_fields)
      created_object = self.from_hash(attrs)

      # If this is an auxilary class (on recursive run), make sure the main class is linked to this auxilary class
      created_object.send("#{related_class}=", related_obj) if related_class

      pp created_object
      # created_object.save! todo - return to this after testing


      # Recursive call to this import_row function. This means that any auxilary class is expected to
      # also use this helper
      if self.external_classes
        self.external_classes.each do |external_class|
          external_class.import_row(row, file, mapping, use_header, self.class.name, created_object)
        end
      end
    end
  end



  # Instance method to serialize a record for export
  def to_hash(fields = self.class.import_export_fields)
    fields.to_h { |f| [f, send(f)] }
  end
end