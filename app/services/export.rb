# app/services/export.rb

##
# Export
#
# This service provides simple, consistent export functionality for any
# array of hashes. Each hash represents one “row” of data, and the keys
# represent column names. The Export class can convert these rows
# into CSV, JSON, or XML.
#
# Example input format:
#   [
#     { id: 1, name: "Team 1", members: "Alice,Bob" },
#     { id: 2, name: "Team 2", members: "Carol,Dan" }
#   ]
#
# The class intentionally does NOT perform queries itself — it expects
# the controller or the caller to assemble the dataset.
#
class Export

  ##
  # Convert the dataset into CSV format.
  #
  # This generates:
  #   • A header row using the keys of the first hash
  #   • One CSV row for each hash using its values
  #
  # Example output:
  #   id,name,members
  #   1,Team 1,Alice; Bob
  #   2,Team 2,Carol; Dan
  #
  def self.perform(export_class, ordered_headers)
    mapping = FieldMapping.from_header(export_class, ordered_headers)

    CSV.generate do |csv|
      class_fields = mapping.ordered_fields.select{ |ele| export_class.internal_fields.include?(ele) }


      # Extract column headers from the first row's keys
      csv << ordered_headers

      # Insert each row in order, using the values of the hash
      export_class.all.each do |record|
        row = class_fields.map{|f| record.send(f)}

        export_class.external_classes.each do |external_class|
          ext_class_fields = mapping.ordered_fields.select{ |ele| external_class.fields.include?(ele) }
          found_record = record.send(external_class.ref_class.name.underscore)
          row += ext_class_fields.map do |f|
            found_record.send(ExternalClass.unappended_class_name(external_class.ref_class, f)) if f
          end
        end

        csv << row
      end
    end
  end

end
