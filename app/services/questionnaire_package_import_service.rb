# frozen_string_literal: true

require 'csv'
require 'json'
require 'set'
require 'zip'

# Custom questionnaire-template import. It coordinates several CSVs in one
# transaction, which the generic single-model importer cannot do.
class QuestionnairePackageImportService
  PACKAGE_TYPE = QuestionnairePackageExportService::PACKAGE_TYPE
  VERSION = QuestionnairePackageExportService::VERSION
  REQUIRED_FILES = %w[manifest.json questionnaires.csv items.csv question_advices.csv].freeze
  QUESTIONNAIRE_REQUIRED_HEADERS = %w[
    name
    questionnaire_type
    display_type
    private
    min_question_score
    max_question_score
    instruction_loc
    instructor_name
  ].freeze
  ITEM_REQUIRED_HEADERS = %w[
    questionnaire_name
    questionnaire_instructor_name
    seq
    txt
    question_type
    weight
    break_before
  ].freeze
  QUESTION_ADVICE_REQUIRED_HEADERS = %w[
    questionnaire_name
    questionnaire_instructor_name
    item_seq
    item_txt
    score
    advice
  ].freeze
  CSV_HEADER_REQUIREMENTS = {
    questionnaires: QUESTIONNAIRE_REQUIRED_HEADERS,
    items: ITEM_REQUIRED_HEADERS,
    question_advices: QUESTION_ADVICE_REQUIRED_HEADERS
  }.freeze
  DEFAULT_DUPLICATE_ACTION = ChangeOffendingFieldAction.new

  def initialize(package_file: nil, questionnaire_file: nil, items_file: nil, question_advices_file: nil, dup_action: nil)
    @package_file = package_file
    @questionnaire_file = questionnaire_file
    @items_file = items_file
    @question_advices_file = question_advices_file
    @duplicate_action = dup_action || DEFAULT_DUPLICATE_ACTION
  end

  # Import parents before dependent rows, using package keys instead of DB IDs.
  def perform
    csv_sources = resolve_csv_sources

    questionnaire_rows = parse_csv(csv_sources.fetch(:questionnaires), :questionnaires)
    item_rows = parse_csv(csv_sources[:items], :items)
    question_advice_rows = parse_csv(csv_sources[:question_advices], :question_advices)

    imported_counts = {
      questionnaires: 0,
      items: 0,
      question_advices: 0
    }
    duplicate_counts = {
      questionnaires: 0,
      items: 0,
      question_advices: 0
    }

    ActiveRecord::Base.transaction do
      imported_questionnaires, skipped_questionnaire_keys = import_questionnaires(
        questionnaire_rows,
        imported_counts,
        duplicate_counts
      )
      imported_items = import_items(item_rows, imported_questionnaires, skipped_questionnaire_keys, imported_counts)
      import_question_advices(
        question_advice_rows,
        imported_questionnaires,
        imported_items,
        skipped_questionnaire_keys,
        imported_counts
      )
    end

    {
      imported: imported_counts,
      duplicates: duplicate_counts
    }
  end

  private

  # Accept either the canonical zip or separate role-specific CSV uploads.
  def resolve_csv_sources
    if @package_file.present?
      entries = read_zip_entries
      validate_package!(entries)
      return {
        questionnaires: entries['questionnaires.csv'],
        items: entries['items.csv'],
        question_advices: entries['question_advices.csv']
      }
    end

    raise StandardError, 'A questionnaire CSV file is required.' if @questionnaire_file.blank?

    {
      questionnaires: read_uploaded_file(@questionnaire_file),
      items: read_uploaded_file(@items_file),
      question_advices: read_uploaded_file(@question_advices_file)
    }
  end

  # Read package entries by zip path; manifest validation happens next.
  def read_zip_entries
    entries = {}

    Zip::File.open(@package_file.path) do |zip_file|
      zip_file.each do |entry|
        next if entry.directory?

        entries[entry.name] = entry.get_input_stream.read
      end
    end

    entries
  rescue Zip::Error => e
    raise StandardError, "Invalid questionnaire package: #{e.message}"
  end

  def read_uploaded_file(file)
    return nil if file.blank?

    file.respond_to?(:read) ? file.read : File.read(file.path)
  ensure
    file.rewind if file.respond_to?(:rewind)
  end

  # Reject unrelated or unsupported package versions before reading CSV rows.
  def validate_package!(entries)
    missing_files = REQUIRED_FILES - entries.keys
    raise StandardError, "Questionnaire package is missing required files: #{missing_files.join(', ')}" if missing_files.any?

    manifest = JSON.parse(entries['manifest.json'])
    unless manifest['package_type'] == PACKAGE_TYPE
      raise StandardError, "Unsupported questionnaire package type: #{manifest['package_type']}"
    end

    return if manifest['version'].to_i == VERSION

    raise StandardError, "Unsupported questionnaire package version: #{manifest['version']}"
  rescue JSON::ParserError => e
    raise StandardError, "Invalid questionnaire package manifest: #{e.message}"
  end

  # Normalize headers before validation so CSVs match FieldMapping behavior.
  def parse_csv(contents, role)
    return [] if contents.blank?

    contents = normalize_csv_contents(contents)
    table = CSV.parse(contents, headers: true)
    headers = table.headers.map { |header| normalize_header(header) }
    rows = table.map do |row|
      row.to_h.transform_keys { |key| normalize_header(key) }
    end
    validate_headers!(role, headers)
    rows
  rescue CSV::MalformedCSVError => e
    raise StandardError, "Invalid #{csv_label(role)} CSV: #{e.message}"
  end

  # Fail early with header errors instead of later relationship errors.
  def validate_headers!(role, headers)
    missing_headers = CSV_HEADER_REQUIREMENTS.fetch(role) - headers
    return if missing_headers.empty?

    raise StandardError, "#{csv_label(role)} CSV is missing required headers: #{missing_headers.join(', ')}"
  end

  def csv_label(role)
    role.to_s.humanize
  end

  def normalize_header(header)
    header.to_s.parameterize.underscore
  end

  # Tolerate common spreadsheet-export encoding issues.
  def normalize_csv_contents(contents)
    contents.to_s.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace)
  end

  # Track imported questionnaires so dependent CSVs can attach to them.
  def import_questionnaires(rows, imported_counts, duplicate_counts)
    mapping = FieldMapping.from_header(Questionnaire, rows.first&.keys || [])
    imported_questionnaires = {}
    skipped_questionnaire_keys = Set.new

    rows.each do |row|
      source_key = questionnaire_source_key(row['name'], row['instructor_name'])
      record, duplicate, skipped = import_questionnaire_row(row, mapping)
      if skipped
        skipped_questionnaire_keys.add(source_key)
        duplicate_counts[:questionnaires] += 1
        next
      end

      next if record.nil?

      imported_questionnaires[source_key] = record
      imported_counts[:questionnaires] += 1
      duplicate_counts[:questionnaires] += 1 if duplicate
    end

    [imported_questionnaires, skipped_questionnaire_keys]
  end

  # Resolve questionnaire duplicates before importing dependent rows.
  def import_questionnaire_row(row, mapping)
    incoming = build_questionnaire(row, mapping)
    existing = find_questionnaire_record(row)

    if existing.nil?
      incoming.save!
      return [incoming, false, false]
    end

    processed = resolve_duplicate_questionnaire(existing, incoming)
    return [existing, true, true] if processed.nil?

    processed.save!
    [processed, true, false]
  end

  # Recreate template items and keep a lookup for advice rows.
  def import_items(rows, imported_questionnaires, skipped_questionnaire_keys, imported_counts)
    imported_items = {}

    rows.each do |row|
      source_key = questionnaire_source_key(row['questionnaire_name'], row['questionnaire_instructor_name'])
      next if skipped_questionnaire_keys.include?(source_key)

      questionnaire = imported_questionnaires[source_key]
      raise StandardError, "Unable to resolve questionnaire for item '#{row['txt']}'." if questionnaire.nil?

      item = Item.new(
        txt: row['txt'],
        weight: row['weight'],
        seq: row['seq'],
        question_type: row['question_type'],
        size: row['size'],
        alternatives: row['alternatives'],
        break_before: normalize_boolean(row['break_before']),
        min_label: row['min_label'],
        max_label: row['max_label']
      )
      item.questionnaire = questionnaire

      imported_seq = item.seq
      item.save!
      item.update_column(:seq, imported_seq) if imported_seq.present? && item.seq.to_s != imported_seq.to_s

      imported_items[item_source_key(row['questionnaire_name'], row['questionnaire_instructor_name'], row['seq'], row['txt'])] = item
      imported_counts[:items] += 1
    end

    imported_items
  end

  # Prefer package item keys, with a DB fallback for update flows.
  def import_question_advices(rows, imported_questionnaires, imported_items, skipped_questionnaire_keys, imported_counts)
    rows.each do |row|
      source_key = questionnaire_source_key(row['questionnaire_name'], row['questionnaire_instructor_name'])
      next if skipped_questionnaire_keys.include?(source_key)

      questionnaire = imported_questionnaires[source_key]
      raise StandardError, "Unable to resolve questionnaire for advice '#{row['advice']}'." if questionnaire.nil?

      item = imported_items[item_source_key(row['questionnaire_name'], row['questionnaire_instructor_name'], row['item_seq'], row['item_txt'])] ||
             questionnaire.items.find_by(seq: row['item_seq'], txt: row['item_txt'])
      raise StandardError, "Unable to resolve item for advice '#{row['advice']}'." if item.nil?

      question_advice = QuestionAdvice.new(
        score: row['score'],
        advice: row['advice']
      )
      question_advice.item = item
      question_advice.save!

      imported_counts[:question_advices] += 1
    end
  end

  # Scope duplicates by instructor name because packages avoid DB IDs.
  def find_questionnaire_record(row)
    instructor = Instructor.find_by(name: row['instructor_name'])
    return nil if instructor.nil?

    Questionnaire.find_by(name: row['name'], instructor_id: instructor.id)
  end

  # Reuse existing mapping so questionnaire conversion stays consistent.
  def build_questionnaire(row, mapping)
    row_values = mapping.ordered_fields.map { |field| row[field] }
    row_hash = {}
    mapping.ordered_fields.zip(row_values).each do |key, value|
      row_hash[key] ||= []
      row_hash[key] << value
    end

    questionnaire = Questionnaire.from_hash(row_hash.slice(*Questionnaire.internal_fields))
    Questionnaire.external_classes.each do |external_class|
      next unless external_class.should_look_up

      found = external_class.look_up(row_hash)
      questionnaire.public_send("#{external_class.ref_class.name.downcase}=", found) if found
    end

    questionnaire
  end

  # Translate selected duplicate action into package-level behavior.
  def resolve_duplicate_questionnaire(existing, incoming)
    case @duplicate_action
    when SkipRecordAction
      nil
    when UpdateExistingRecordAction
      update_existing_questionnaire(existing, incoming)
    else
      incoming.name = unique_questionnaire_name(incoming.name, incoming.instructor_id)
      incoming
    end
  end

  # Update only template fields represented in the package CSV.
  def update_existing_questionnaire(existing, incoming)
    existing.assign_attributes(
      incoming.attributes.slice(
        'questionnaire_type',
        'display_type',
        'private',
        'min_question_score',
        'max_question_score',
        'instruction_loc'
      )
    )
    existing
  end

  # Default duplicate handling preserves both records with a readable copy name.
  def unique_questionnaire_name(name, instructor_id)
    base = name.to_s
    candidate = base
    counter = 1

    while Questionnaire.exists?(name: candidate, instructor_id: instructor_id)
      candidate = "#{base}_copy#{counter == 1 ? '' : counter}"
      counter += 1
    end

    candidate
  end

  # Portable questionnaire key used across package CSVs.
  def questionnaire_source_key(name, instructor_name)
    "#{instructor_name}::#{name}"
  end

  # Portable item key used by advice rows.
  def item_source_key(questionnaire_name, instructor_name, seq, txt)
    "#{questionnaire_source_key(questionnaire_name, instructor_name)}::#{seq}::#{txt}"
  end

  # Spreadsheet uploads provide booleans as strings.
  def normalize_boolean(value)
    ActiveRecord::Type::Boolean.new.deserialize(value)
  end
end
