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
  # @param data [Array<Hash>]
  #   A list of row hashes. Keys must be consistent across all rows.
  #
  def initialize(data)
    @data = data
  end

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
  def to_csv
    CSV.generate do |csv|
      # Extract column headers from the first row's keys
      csv << @data.first.keys

      # Insert each row in order, using the values of the hash
      @data.each do |row|
        csv << row.values
      end
    end
  end

  ##
  # Convert the data into JSON format.
  #
  # Produces:
  #   [
  #     { "id": 1, "name": "Team 1", "members": "Alice; Bob" },
  #     { "id": 2, "name": "Team 2", "members": "Carol; Dan" }
  #   ]
  #
  def to_json
    @data.to_json
  end

  ##
  # Convert the data into XML format.
  #
  # Produces:
  #   <records>
  #     <record>
  #       <id>1</id>
  #       <name>Team 1</name>
  #       <members>Alice; Bob</members>
  #     </record>
  #     ...
  #   </records>
  #
  # Using skip_types avoids type metadata inside XML nodes.
  #
  def to_xml
    @data.to_xml(
      root: 'records',     # wrap all rows in <records>
      skip_types: true     # cleaner XML, no type="integer" noise
    )
  end
end
