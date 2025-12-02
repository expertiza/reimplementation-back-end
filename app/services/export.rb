# app/services/export.rb
class Export
  def initialize(data)
    @data = data
  end

  def to_csv
    CSV.generate do |csv|
      csv << @data.first.keys
      @data.each { |row| csv << row.values }
    end
  end

  def to_json
    @data.to_json
  end

  def to_xml
    @data.to_xml(root: 'records', skip_types: true)
  end
end
