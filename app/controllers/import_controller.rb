# This controller handles importing CSV data into any supported model.
# It exposes two endpoints:
#   • GET  /import        -> returns field requirements for the selected class
#   • POST /import        -> processes the uploaded CSV file
#
# The controller delegates actual import logic to:
#   klass.try_import_records(...)
#
# Each model that supports importing must implement:
#   mandatory_fields
#   optional_fields
#   external_fields
#   try_import_records(file, ordered_fields, use_header:)
#

class ImportController < ApplicationController
  # Ensure strong parameters are processed before each action
  before_action :import_params

  ##
  # GET /import
  #
  # Returns metadata about which fields a given class requires or accepts.
  # The frontend uses this to build the mapping UI (drag/drop field matching).
  #
  def index
    imported_class = params[:class].constantize

    render json: {
      mandatory_fields: imported_class.mandatory_fields,
      optional_fields: imported_class.optional_fields,
      external_fields: imported_class.external_fields,

      # Import does not provide duplicate-resolution strategies (those apply to export)
      available_actions_on_dup: imported_class.available_actions_on_duplicate.map{|klass| klass.class.name},
    }, status: :ok
  end

  ##
  # POST /import
  #
  # This action performs the actual import process. It:
  #   1. Reads the uploaded CSV file
  #   2. Determines whether the CSV includes headers
  #   3. Applies user-chosen field ordering (if provided)
  #   4. Hands off import logic to the model via `try_import_records`
  #
  def import
    uploaded_file  = params[:csv_file]

    # Convert use_headers ("true"/"false") into actual boolean
    use_headers    = ActiveRecord::Type::Boolean.new.deserialize(params[:use_headers])

    # If the user provided a custom field ordering, load it from JSON
    ordered_fields = JSON.parse(params[:ordered_fields]) if params[:ordered_fields]

    # Dynamically load the model class (e.g., "User", "Team", etc.)
    klass = params[:class].constantize

    # Load the chosen duplicate action (Skip, Update, Change)
    dup_action = params[:dup_action].constantize

    pp dup_action

    importService = Import.new(klass: klass, file: uploaded_file, headers: ordered_fields, dup_action: dup_action.new)
    result = importService.perform(use_headers)

    # If no exceptions occur, return success
    render json: { message: "#{klass.name} has been imported!", **result }, status: :created

  rescue StandardError => e
    # Catch any unexpected runtime errors
    puts "An unexpected error occurred during import: #{e.message}"

    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  ##
  # Strong parameters for import operations
  #
  def import_params
    params.permit(:csv_file, :use_headers, :class, :ordered_fields, :dup_action)
  end
end
