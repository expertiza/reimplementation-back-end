class Api::V1::SubmittedContentController < ApplicationController
  include SubmittedContentHelper
  include FileHelper

  before_action :set_submission_record, only: [:show]
  before_action :set_participant, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]
  before_action :ensure_participant_team, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]

  # GET /api/v1/submitted_content
  # Retrieves all submission records from the database
  def index
    # Return all submission records as JSON with 200 OK status
    render json: SubmissionRecord.all, status: :ok
  end

  # GET /api/v1/submitted_content/:id
  # Retrieves a specific submission record by ID (set by before_action)
  def show
    # @submission_record is set by set_submission_record before_action
    render json: @submission_record, status: :ok
  end

  # POST /api/v1/submitted_content
  # Creates a new submission record with automatic type detection (hyperlink or file)
  def create
    # Get permitted parameters from request
    attrs = submitted_content_params

    # Auto-detect record type: if content starts with 'http', it's a hyperlink, otherwise file
    attrs[:record_type] ||= attrs[:content].to_s.start_with?('http') ? 'hyperlink' : 'file'

    # Create new record with the attributes
    record = SubmissionRecord.new(attrs)

    # Attempt to save and return appropriate response
    if record.save
      render json: record, status: :created
    else
      render json: record.errors, status: :unprocessable_content
    end
  end

  # POST /api/v1/submitted_content/submit_hyperlink
  # GET  /api/v1/submitted_content/submit_hyperlink
  # Validates and submits a hyperlink for the participant's team
  def submit_hyperlink
    # Get the participant's team (requires @participant from before_action)
    team = participant_team

    # Clean up the submitted hyperlink by stripping whitespace
    submission = params[:submission].to_s.strip

    # Validate that the hyperlink is not blank
    if submission.blank?
      return render_error('Hyperlink submission cannot be blank. Please provide a valid URL.', :bad_request)
    end

    # Check for duplicate hyperlinks in the team's existing submissions
    if team.hyperlinks.include?(submission)
      return render_error('You or your teammate(s) have already submitted the same hyperlink.', :conflict)
    end

    # Attempt to submit the hyperlink and record the submission
    begin
      # Add hyperlink to team's submission list (validates URL format)
      team.submit_hyperlink(submission)

      # Create a submission record for audit trail
      create_submission_record_for('hyperlink', submission, 'Submit Hyperlink')

      # Return success response
      render_success('The link has been successfully submitted.')
    rescue StandardError => e
      # Handle any errors during hyperlink submission (invalid URL, network issues, etc.)
      render_error("The URL or URI is invalid. Reason: #{e.message}", :bad_request)
    end
  end

  # POST /api/v1/submitted_content/remove_hyperlink
  # GET  /api/v1/submitted_content/remove_hyperlink
  # Removes a hyperlink at the specified index from the team's hyperlinks
  def remove_hyperlink
    # Get the participant's team
    team = participant_team

    # Get the index of the hyperlink to delete from params
    index = params['chk_links'].to_i

    # Retrieve the hyperlink at the specified index
    hyperlink_to_delete = team.hyperlinks[index]

    # Validate that a hyperlink exists at this index
    unless hyperlink_to_delete
      return render_error('Hyperlink not found at the specified index. It may have already been removed.', :not_found)
    end

    # Attempt to remove the hyperlink
    begin
      # Remove the hyperlink from team's submission list
      team.remove_hyperlink(hyperlink_to_delete)

      # Create a submission record for the removal action
      create_submission_record_for('hyperlink', hyperlink_to_delete, 'Remove Hyperlink')

      # Return 204 No Content for successful deletion
      head :no_content
    rescue StandardError => e
      # Handle any errors during removal (database errors, etc.)
      render_error("Failed to remove hyperlink from team submissions due to a server error: #{e.message}. Please try again or contact support if the issue persists.", :internal_server_error)
    end
  end

  # POST /api/v1/submitted_content/submit_file
  # GET  /api/v1/submitted_content/submit_file
  # Handles file upload for the participant's team with validation and optional unzipping
  def submit_file
    # Get the uploaded file from request parameters
    uploaded = params[:uploaded_file]

    # Validate that a file was provided
    return render_error('No file provided. Please select a file to upload using the "uploaded_file" parameter.', :bad_request) unless uploaded

    # Define file size limit (5MB)
    file_size_limit_mb = 5

    # Validate file size against the limit
    unless check_content_size(uploaded, file_size_limit_mb)
      return render_error("File size must be smaller than #{file_size_limit_mb}MB", :bad_request)
    end

    # Validate file extension against allowed types
    unless check_extension_integrity(uploaded_file_name(uploaded))
      return render_error('File extension not allowed. Supported formats: pdf, png, jpeg, jpg, zip, tar, gz, 7z, odt, docx, md, rb, mp4, txt.', :bad_request)
    end

    # Read the file contents into memory
    file_bytes = uploaded.read

    # Get the current folder from params, default to root '/'
    current_folder = sanitize_folder(params.dig(:current_folder, :name) || '/')

    # Get team and ensure it has a directory number assigned
    team = participant_team
    team.set_student_directory_num

    # Build the full directory path where file will be saved
    current_directory = File.join(@participant.team_path.to_s, current_folder)

    # Create the directory if it doesn't exist
    FileUtils.mkdir_p(current_directory) unless File.exist?(current_directory)

    # Sanitize the filename: remove backslashes, replace spaces with underscores
    safe_filename = sanitize_filename(uploaded_file_name(uploaded).tr('\\', '/')).gsub(' ', '_')

    # Build the full file path (use basename to prevent directory traversal)
    full_path = File.join(current_directory, File.basename(safe_filename))

    # Write the file to disk in binary mode
    File.open(full_path, 'wb') { |f| f.write(file_bytes) }

    # If unzip flag is set and file is a zip, extract contents
    if params[:unzip] && file_type(safe_filename) == 'zip'
      SubmittedContentHelper.unzip_file(full_path, current_directory, true)
    end

    # Create submission record for audit trail
    create_submission_record_for('file', full_path, 'Submit File')

    # Return success response with 201 Created status
    render_success('The file has been submitted successfully.', :created)
  rescue StandardError => e
    # Handle any errors during file upload (disk space, permissions, corruption, etc.)
    render_error("Failed to save file to server: #{e.message}. Please verify the file is not corrupted and try again.", :internal_server_error)
  end

  # POST /api/v1/submitted_content/folder_action
  # GET  /api/v1/submitted_content/folder_action
  # Dispatches folder management actions based on the faction parameter
  def folder_action
    # Get the faction parameter (specifies which action to perform)
    faction = params[:faction] || {}

    # Route to appropriate action based on which faction key is present
    if faction[:delete].present?
      delete_selected_files
    elsif faction[:rename].present?
      rename_selected_file
    elsif faction[:move].present?
      move_selected_file
    elsif faction[:copy].present?
      copy_selected_file
    elsif faction[:create].present?
      create_new_folder
    else
      # No valid action specified, return error
      render_error('No folder action specified. Valid actions: delete, rename, move, copy, create. Provide one in the "faction" parameter.', :bad_request)
    end
  end

  # GET /api/v1/submitted_content/download
  # Validates and streams a file for download
  def download
    # Extract folder name and file name from params
    folder_name_param = params.dig(:current_folder, :name)
    file_name = params[:download]

    # Validate that folder name was provided
    if folder_name_param.blank?
      return render_error('Folder name is required. Please provide a folder path in the "current_folder[name]" parameter.', :bad_request)
    # Validate that file name was provided
    elsif file_name.blank?
      return render_error('File name is required. Please specify the file to download in the "download" parameter.', :bad_request)
    end

    # Sanitize the folder name to prevent directory traversal attacks
    folder_name = sanitize_folder(folder_name_param)

    # Build the full path to the requested file
    path = File.join(folder_name, file_name)

    # Check if the path is a directory (cannot download directories)
    if File.directory?(path)
      return render_error('Cannot download a directory. Please specify a file path, not a folder path.', :bad_request)
    # Check if the file exists
    elsif !File.exist?(path)
      return render_error("File '#{file_name}' does not exist in the specified folder. Please verify the file name and path.", :not_found)
    end

    # Stream the file to the client (disposition: 'inline' displays in browser if possible)
    # Note: send_file returns immediately, do NOT render after this line
    send_file(path, disposition: 'inline')
  end

  private

  # Before action callback: Sets @submission_record for the show action
  def set_submission_record
    # Find the submission record by ID from params
    @submission_record = SubmissionRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    # Return 404 if record not found
    render json: { error: e.message }, status: :not_found and return
  end

  # Before action callback: Sets @participant for actions that require participant context
  def set_participant
    # Find the participant by ID from params
    # @participant is kept as instance variable because it's set by before_action
    @participant = AssignmentParticipant.find(params[:id])
  end

  # Before action callback: Ensures participant has an associated team
  def ensure_participant_team
    # Check that participant exists and has a team
    unless @participant && @participant.team
      render json: { error: 'Participant is not associated with a team. Please ensure the participant has joined a team before performing this action.' }, status: :not_found and return
    end
  end

  # Strong parameters for submission record creation
  def submitted_content_params
    # Permit only specified attributes for security
    params.require(:submitted_content).permit(:id, :content, :operation, :team_id, :user, :assignment_id, :record_type)
  end

  # Returns the participant's team (local method, no instance variable caching)
  def participant_team
    # Simply return the team associated with @participant
    # Note: @participant is set by before_action, so it's safe to use here
    @participant.team
  end

  # Renders an error response with the given message and HTTP status
  def render_error(message, status = :unprocessable_content)
    # Render JSON error response with specified status code
    render json: { error: message }, status: status
  end

  # Renders a success response with the given message and HTTP status
  def render_success(message, status = :ok)
    # Render JSON success response with specified status code
    render json: { message: message }, status: status
  end

  # Safely extracts filename from uploaded file object or string
  def uploaded_file_name(uploaded)
    # Check if uploaded object has original_filename method (ActionDispatch::Http::UploadedFile)
    if uploaded.respond_to?(:original_filename)
      uploaded.original_filename
    else
      # Fallback to string representation
      uploaded.to_s
    end
  end

  # Creates a submission record for audit trail (used by both file and hyperlink operations)
  def create_submission_record_for(record_type, content, operation)
    # Create a new submission record with participant and team information
    # Note: @participant is set by before_action, safe to access here
    SubmissionRecord.create!(
      record_type: record_type,           # 'file' or 'hyperlink'
      content: content,                    # File path or URL
      user: @participant.user_name,        # Username from participant
      team_id: @participant.team_id,       # Team ID from participant
      assignment_id: @participant.assignment_id,  # Assignment ID from participant
      operation: operation                 # Operation description (e.g., 'Submit File')
    )
  end
end
