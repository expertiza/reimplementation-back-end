# app/services/export.rb

##
# Export
#
# This service provides CSV export for models that expose import/export
# metadata. The model supplies the record scope through its filter, while
# FieldMapping controls the order and translation of requested headers.
#
class Export

  ##
  # Convert model records into CSV format.
  #
  # This generates:
  #   * A header row using the requested export headers
  #   * One CSV row for each record in the model's export scope
  #
  # Example output:
  #   name,participant_1,participant_2
  #   Team 1,alice,bob
  #
  def self.export_csv(export_class, ordered_headers)
    ordered_headers ||= export_class.internal_and_external_fields
    mapping = FieldMapping.from_header(export_class, ordered_headers)

    csv_contents = CSV.generate do |csv|
      class_fields = mapping.ordered_fields.select { |ele| export_class.internal_fields.include?(ele) }

      # Preserve the selected frontend field order in the CSV header.
      csv << ordered_headers

      # Insert each scoped model record in the same selected field order.
      export_class.filter.call.each do |record|
        row = class_fields.map { |f| record.send(f) }

        Array(export_class.external_classes).each do |external_class|
          ext_class_fields = mapping.ordered_fields.select { |ele| external_class.fields.include?(ele) }
          found_record = record.send(external_class.ref_class.name.underscore)
          row += ext_class_fields.map do |f|
            found_record&.send(ExternalClass.unappended_class_name(external_class.ref_class, f)) if f
          end
        end

        csv << row
      end
    end

    [{ name: export_class.name, contents: csv_contents }]
  end

  def self.perform(export_class, ordered_headers = nil)
    export_csv(export_class, ordered_headers)
  end

end
