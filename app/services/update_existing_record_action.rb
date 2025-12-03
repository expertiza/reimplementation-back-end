class UpdateExistingRecordAction

  def on_duplicate_record(klass, records)
    merged = {}

    existing = records[:existing]

    klass.mandatory_fields.each do |field|
      value = {}
      value[field] = records[:incoming].send(field)
      existing.send(:assign_attributes, value)
    end

    existing
  end
end