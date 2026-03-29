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

    render json: import_metadata_for(imported_class), status: :ok
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
    defaults = import_defaults_for(klass)

    # Load the chosen duplicate action (Skip, Update, Change)
    dup_action = params[:dup_action]&.constantize

    pp dup_action

    importService = Import.new(klass: klass, file: uploaded_file, headers: ordered_fields, dup_action: dup_action&.new, defaults: defaults)
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
    params.permit(:csv_file, :use_headers, :class, :ordered_fields, :dup_action, :assignment_id)
  end

  def import_defaults_for(klass)
    return team_import_defaults if klass == Team
    return {} unless klass == User && current_user.present?

    {
      parent_id: current_user.id,
      institution_id: current_user.institution_id
    }
  end

  def import_metadata_for(imported_class)
    if imported_class == Team
      Team.with_assignment_context(params[:assignment_id]) do
        return {
          mandatory_fields: imported_class.mandatory_fields,
          optional_fields: imported_class.optional_fields,
          external_fields: imported_class.external_fields,
          available_actions_on_dup: imported_class.available_actions_on_duplicate.map { |klass| klass.class.name }
        }
      end
    end

    {
      mandatory_fields: imported_class.mandatory_fields,
      optional_fields: imported_class.optional_fields,
      external_fields: imported_class.external_fields,
      available_actions_on_dup: imported_class.available_actions_on_duplicate.map { |klass| klass.class.name }
    }
  end

  def team_import_defaults
    return {} if params[:assignment_id].blank?

    { assignment_id: params[:assignment_id].to_i }
  end
end
