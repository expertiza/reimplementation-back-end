class Api::V1::SubmittedContentController < ApplicationController
  include SubmittedContentHelper
  include FileHelper

  before_action :set_submission_record, only: [:show]
  before_action :set_participant, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]
  before_action :ensure_participant_team, only: [:submit_hyperlink, :remove_hyperlink, :submit_file, :folder_action, :download]

  # GET /api/v1/submitted_content
  def index
    render json: SubmissionRecord.all, status: :ok
  end

  # GET /api/v1/submitted_content/:id
  def show
    render json: @submission_record, status: :ok
  end

  # POST /api/v1/submitted_content
  def create
    attrs = submitted_content_params
    attrs[:record_type] ||= attrs[:content].to_s.start_with?('http') ? 'hyperlink' : 'file'
    record = SubmissionRecord.new(attrs)

    if record.save
      render json: record, status: :created
    else
      render json: record.errors, status: :unprocessable_entity
    end
  end

  # POST /api/v1/submitted_content/submit_hyperlink
  # GET  /api/v1/submitted_content/submit_hyperlink
  def submit_hyperlink
    team = @participant.team
    submission = params[:submission].to_s.strip

    if submission.blank?
      return render json: { error: 'Submission cannot be blank' }, status: :bad_request
    end

    if team.hyperlinks.include?(submission)
      return render json: { message: 'You or your teammate(s) have already submitted the same hyperlink.' }, status: :unprocessable_entity
    end

    begin
      team.submit_hyperlink(submission)
      create_submission_record_for('hyperlink', submission, 'Submit Hyperlink')
      render json: { message: 'The link has been successfully submitted.' }, status: :ok
    rescue StandardError => e
      render json: { error: "The URL or URI is invalid. Reason: #{e.message}" }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/submitted_content/remove_hyperlink
  # GET  /api/v1/submitted_content/remove_hyperlink
  def remove_hyperlink
    team = @participant.team
    index = params['chk_links'].to_i
    hyperlink_to_delete = team.hyperlinks[index]

    unless hyperlink_to_delete
      return render json: { error: 'Hyperlink not found' }, status: :not_found
    end

    begin
      team.remove_hyperlink(hyperlink_to_delete)
      create_submission_record_for('hyperlink', hyperlink_to_delete, 'Remove Hyperlink')
      head :no_content
    rescue StandardError => e
      render json: { error: "There was an error deleting the hyperlink. Reason: #{e.message}" }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/submitted_content/submit_file
  # GET  /api/v1/submitted_content/submit_file
  def submit_file
    uploaded = params[:uploaded_file]
    return render json: { error: 'No file provided' }, status: :bad_request unless uploaded

    file_size_limit_mb = 5
    unless check_content_size(uploaded, file_size_limit_mb)
      return render json: { error: "File size must be smaller than #{file_size_limit_mb}MB" }, status: :bad_request
    end

    unless check_extension_integrity(uploaded.original_filename)
      render json: { error: 'File extension does not match' }, status: :unprocessable_entity
      return
    end

    file_bytes = uploaded.read
    current_folder = sanitize_folder(params.dig(:current_folder, :name) || '/')
    team = @participant.team
    team.set_student_directory_num

    current_directory = File.join(team.path.to_s, current_folder)
    FileUtils.mkdir_p(current_directory) unless File.exist?(current_directory)

    safe_filename = sanitize_filename(uploaded.original_filename.tr('\\', '/')).gsub(' ', '_')
    full_path = File.join(current_directory, File.basename(safe_filename))

    # Save file
    File.open(full_path, 'wb') { |f| f.write(file_bytes) }

    # Unzip if requested and allowed
    if params[:unzip] && file_type(safe_filename) == 'zip'
      SubmittedContentHelper.unzip_file(full_path, current_directory, true)
    end

    create_submission_record_for('file', full_path, 'Submit File')
    render json: { message: 'The file has been submitted.' }, status: :ok
  rescue StandardError => e
    render json: { error: "File submission failed: #{e.message}" }, status: :unprocessable_entity
  end

  # POST /api/v1/submitted_content/folder_action
  # GET  /api/v1/submitted_content/folder_action
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
      render json: { error: 'No folder action specified' }, status: :bad_request
    end
  end

  # GET /api/v1/submitted_content/download
  def download
    folder_name = sanitize_folder(params.dig(:current_folder, :name) || '/')
    file_name = params[:download]

    if folder_name.blank?
      return render json: { message: 'Folder_name is nil.' }, status: :bad_request
    elsif file_name.blank?
      return render json: { message: 'File name is nil.' }, status: :bad_request
    end

    path = File.join(folder_name, file_name)
    if File.directory?(path)
      return render json: { message: 'Cannot send a whole folder.' }, status: :bad_request
    elsif !File.exist?(path)
      return render json: { message: 'File does not exist.' }, status: :not_found
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
      render json: { error: 'Participant or team not found' }, status: :not_found and return
    end
  end

  def submitted_content_params
    params.require(:submitted_content).permit(:id, :content, :operation, :team_id, :user, :assignment_id, :record_type)
  end

  # single place to create records for both files and hyperlinks
  def create_submission_record_for(record_type, content, operation)
    SubmissionRecord.create!(
      record_type: record_type,
      content: content,
      user: @participant.user.try(:name),
      team_id: @participant.team.try(:id),
      assignment_id: @participant.assignment.try(:id),
      operation: operation
    )
  end
end
