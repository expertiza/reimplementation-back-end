# frozen_string_literal: true

require 'csv'

# A module because Rails loads every *_helper.rb file as a view helper.
module ProjectTopicCsvImportHelper
  # Imports an assignment's topics from a CSV file, all rows or none.
  class Importer
    class Error < StandardError; end

    MANDATORY_FIELDS = %w[topic_identifier topic_name max_choosers].freeze
    OPTIONAL_FIELDS = %w[category description link].freeze
    FIELDS = (MANDATORY_FIELDS + OPTIONAL_FIELDS).freeze

    def initialize(assignment:, content:, use_headers:, ordered_fields: nil)
      @assignment = assignment
      @content = content
      @use_headers = use_headers
      @ordered_fields = ordered_fields
    end

    # Returns { created:, updated: } or raises Error.
    def call
      rows = parse
      header = @use_headers ? rows.shift&.first : @ordered_fields
      columns = map_columns(header)
      raise Error, 'The file has no topic rows.' if rows.empty?

      save_all(rows, columns)
    end

    private

    # [[cells, row_number], ...] without blank lines.
    def parse
      text = @content.dup.force_encoding(Encoding::UTF_8)
      raise Error, 'The file must be UTF-8 encoded CSV.' unless text.valid_encoding?

      CSV.parse(text.delete_prefix("\uFEFF"))
         .each.with_index(1)
         .reject { |cells, _| cells.all?(&:blank?) }
    rescue CSV::MalformedCSVError => e
      raise Error, "Invalid CSV: #{e.message}"
    end

    # Maps each column position to a known field name, or nil to ignore it.
    def map_columns(header)
      by_key = FIELDS.index_by { |field| normalize(field) }
      columns = Array(header).map { |name| by_key[normalize(name)] }

      missing = MANDATORY_FIELDS - columns
      raise Error, "Missing required columns: #{missing.join(', ')}" if missing.any?
      raise Error, 'A column appears more than once.' if columns.compact.uniq != columns.compact

      columns
    end

    def normalize(name)
      name.to_s.downcase.delete(' _')
    end

    def save_all(rows, columns)
      counts = { created: 0, updated: 0 }
      problems = []

      ProjectTopic.transaction do
        rows.each do |cells, number|
          attributes = columns.zip(cells).filter_map { |field, value| [field, value.to_s.strip] if field }.to_h
          result = save_row(attributes)
          result.is_a?(Symbol) ? counts[result] += 1 : problems << "Row #{number}: #{result}"
        end
        raise Error, "Nothing was imported. #{problems.join(' ')}" if problems.any?
      end

      counts
    end

    # Returns :created, :updated, or a description of why the row was rejected.
    def save_row(attributes)
      blank = MANDATORY_FIELDS.select { |field| attributes[field].blank? }
      return "#{blank.join(', ')} required." if blank.any?

      topic = @assignment.project_topics.find_or_initialize_by(topic_name: attributes['topic_name'])
      outcome = topic.new_record? ? :created : :updated
      # As in old Expertiza, an existing topic only has its slots and identifier replaced.
      attributes = attributes.slice('max_choosers', 'topic_identifier') if outcome == :updated

      return outcome if topic.update(attributes)

      "#{topic.errors.full_messages.join(', ')}."
    rescue ActiveRecord::ValueTooLong
      'a value is too long.'
    rescue ActiveRecord::RecordNotUnique
      'Topic identifier has already been taken.'
    end
  end
end
