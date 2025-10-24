class Api::V1::SubmittedContentController < ApplicationController
  include SubmittedContentHelper
  include FileHelper

  before_action :set_submission_record, only: [:show]
  before_action :set_participant, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]
  before_action :ensure_participant_team, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]

  # GET /api/v1/submitted_content
  # Retrieves all submission records
  def index
    render json: SubmissionRecord.all, status: :ok
  end

  # GET /api/v1/submitted_content/:id
  # Retrieves a specific submission record by ID
  def show
    render json: @submission_record, status: :ok
  end

  # POST /api/v1/submitted_content
  # Creates a new submission record with automatic type detection (hyperlink or file)
  def create
    attrs = submitted_content_params
    attrs[:record_type] ||= attrs[:content].to_s.start_with?('http') ? 'hyperlink' : 'file'
    record = SubmissionRecord.new(attrs)

    if record.save
      render json: record, status: :created
    else
      render json: record.errors, status: :unprocessable_content
    end
  end

  # POST /api/v1/submitted_content/submit_hyperlink
  # GET  /api/v1/submitted_content/submit_hyperlink
  # Validates and submits a hyperlink for the participant's team
  # Checks for blank submissions and duplicate hyperlinks before creating submission record
  def submit_hyperlink
    team = current_team
    submission = params[:submission].to_s.strip

    if submission.blank?
      return render_error('Hyperlink submission cannot be blank. Please provide a valid URL.', :bad_request)
    end

    if team.hyperlinks.include?(submission)
      return render_error('You or your teammate(s) have already submitted the same hyperlink.', :conflict)
    end

    begin
      team.submit_hyperlink(submission)
      create_submission_record_for('hyperlink', submission, 'Submit Hyperlink')
      render_success('The link has been successfully submitted.')
    rescue StandardError => e
      render_error("The URL or URI is invalid. Reason: #{e.message}", :bad_request)
    end
  end

  # POST /api/v1/submitted_content/remove_hyperlink
  # GET  /api/v1/submitted_content/remove_hyperlink
  # Removes a hyperlink at the specified index from the team's hyperlinks
  # Creates a submission record for the removal action
  def remove_hyperlink
    team = current_team
    index = params['chk_links'].to_i
    hyperlink_to_delete = team.hyperlinks[index]

    unless hyperlink_to_delete
      return render_error('Hyperlink not found at the specified index. It may have already been removed.', :not_found)
    end

    begin
      team.remove_hyperlink(hyperlink_to_delete)
      create_submission_record_for('hyperlink', hyperlink_to_delete, 'Remove Hyperlink')
      head :no_content
    rescue StandardError => e
      render_error("Failed to remove hyperlink from team submissions due to a server error: #{e.message}. Please try again or contact support if the issue persists.", :internal_server_error)
    end
  end

  # POST /api/v1/submitted_content/submit_file
  # GET  /api/v1/submitted_content/submit_file
  # Handles file upload for the participant's team
  # Validates file presence, size, and extension before saving to team directory
  # Optionally unzips files if requested
  def submit_file
    uploaded = params[:uploaded_file]
    return render_error('No file provided. Please select a file to upload using the "uploaded_file" parameter.', :bad_request) unless uploaded

    file_size_limit_mb = 5
    unless check_content_size(uploaded, file_size_limit_mb)
      return render_error("File size must be smaller than #{file_size_limit_mb}MB", :bad_request)
    end

    unless check_extension_integrity(uploaded_file_name(uploaded))
      return render_error('File extension not allowed. Supported formats: pdf, png, jpeg, jpg, zip, tar, gz, 7z, odt, docx, md, rb, mp4, txt.', :bad_request)
    end

    file_bytes = uploaded.read
    current_folder = sanitize_folder(params.dig(:current_folder, :name) || '/')
    team = current_team
    team.set_student_directory_num

    current_directory = File.join(team.path.to_s, current_folder)
    FileUtils.mkdir_p(current_directory) unless File.exist?(current_directory)

    safe_filename = sanitize_filename(uploaded_file_name(uploaded).tr('\\', '/')).gsub(' ', '_')
    full_path = File.join(current_directory, File.basename(safe_filename))

    # Save file
    File.open(full_path, 'wb') { |f| f.write(file_bytes) }

    # Unzip if requested and allowed
    if params[:unzip] && file_type(safe_filename) == 'zip'
      SubmittedContentHelper.unzip_file(full_path, current_directory, true)
    end

    create_submission_record_for('file', full_path, 'Submit File')
    render_success('The file has been submitted successfully.', :created)
  rescue StandardError => e
    render_error("Failed to save file to server: #{e.message}. Please verify the file is not corrupted and try again.", :internal_server_error)
  end

  # POST /api/v1/submitted_content/folder_action
  # GET  /api/v1/submitted_content/folder_action
  # Dispatches folder management actions (delete, rename, move, copy, create)
  # based on the faction parameter
  def folder_action
    faction = params[:faction] || {}
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
      render_error('No folder action specified. Valid actions: delete, rename, move, copy, create. Provide one in the "faction" parameter.', :bad_request)
    end
  end

  # GET /api/v1/submitted_content/download
  # Validates and streams a file for download
  # Ensures the requested path is a file (not directory) and exists before streaming
  def download
    folder_name_param = params.dig(:current_folder, :name)
    file_name = params[:download]

    if folder_name_param.blank?
      return render_error('Folder name is required. Please provide a folder path in the "current_folder[name]" parameter.', :bad_request)
    elsif file_name.blank?
      return render_error('File name is required. Please specify the file to download in the "download" parameter.', :bad_request)
    end

    folder_name = sanitize_folder(folder_name_param)
    path = File.join(folder_name, file_name)

    if File.directory?(path)
      return render_error('Cannot download a directory. Please specify a file path, not a folder path.', :bad_request)
    elsif !File.exist?(path)
      return render_error("File '#{file_name}' does not exist in the specified folder. Please verify the file name and path.", :not_found)
    end

    # send_file will stream and return; do NOT render after send_file
    send_file(path, disposition: 'inline')
  end

  private

  def set_submission_record
    @submission_record = SubmissionRecord.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found and return
  end

  def set_participant
    @participant = AssignmentParticipant.find(params[:id])
  end

  def ensure_participant_team
    unless @participant && @participant.team
      render json: { error: 'Participant is not associated with a team. Please ensure the participant has joined a team before performing this action.' }, status: :not_found and return
    end
  end

  def submitted_content_params
    params.require(:submitted_content).permit(:id, :content, :operation, :team_id, :user, :assignment_id, :record_type)
  end

  # Memoized team retrieval to avoid multiple database calls
  def current_team
    @current_team ||= @participant.team
  end

  # Helper method to render error responses
  def render_error(message, status = :unprocessable_content)
    render json: { error: message }, status: status
  end

  # Helper method to render success responses
  def render_success(message, status = :ok)
    render json: { message: message }, status: status
  end

  # Helper method to safely get filename from uploaded file or string
  def uploaded_file_name(uploaded)
    if uploaded.respond_to?(:original_filename)
      uploaded.original_filename
    else
      uploaded.to_s
    end
  end

  # single place to create records for both files and hyperlinks
  def create_submission_record_for(record_type, content, operation)
    SubmissionRecord.create!(
      record_type: record_type,
      content: content,
      user: @participant.user_name,
      team_id: @participant.team_id,
      assignment_id: @participant.assignment_id,
      operation: operation
    )
  end
end
