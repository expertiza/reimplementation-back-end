class Api::V1::SubmittedContentController < ApplicationController

  include SubmittedContentHelper
  include FileHelper

  # Get /api/v1/submit_content
  def index
    @submission_record = SubmissionRecord.all
    render json: @submission_record, status: :ok
  end

  # GET /api/v1/submitted_content/:id
  def show
    @submission_record = SubmissionRecord.find(params[:id])
    render json: @submission_record, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST   /api/v1/submitted_content
  def create
    @submission_record = SubmissionRecord.create(submitted_content_params)
    if @submission_record.save
      render json: @submission_record, status: :created
    else
      render json: @submission_record.errors, status: :unprocessable_entity
    end
  end

  # POST   /api/v1/submitted_content/submit_hyperlink
  # GET   /api/v1/submitted_content/submit_hyperlink
  # Creates a submission record and submits the hyperlink.
  def submit_hyperlink
    set_participant

    team = @participant.team
    team_hyperlinks = team.hyperlinks
    if team_hyperlinks.include?(params[:submission])
      render json: { message: 'You or your teammate(s) have already submitted the same hyperlink.'},  status: :unprocessable_entity
    else
      submit_hyperlink_and_create_record(team)
    end
  end

  # POST   /api/v1/submitted_content/remove_hyperlink
  # GET   /api/v1/submitted_content/remove_hyperlink
  # Removes hyperlink from team submissions and creates a record.
  def remove_hyperlink
    set_participant

    team = @participant.team
    hyperlink_to_delete = team.hyperlinks[params['chk_links'].to_i]

    remove_hyperlink_and_create_record(hyperlink_to_delete, team)
  end

  # POST   /api/v1/submitted_content/submit_file
  # GET   /api/v1/submitted_content/submit_file
  # To submit file to a specific student directory.
  def submit_file
    set_participant

    @file = params[:uploaded_file]
    file_size_limit = 5    # 5mb

    unless check_content_size(@file, file_size_limit)
      return render json: { message:"File size must be smaller than #{file_size_limit}MB" }, status: :bad_request
    end

    unless check_extension_integrity(@file.original_filename)
      return render json: { message: 'File extension does not match. '\
        'Please upload one of the following: '\
        'pdf, png, jpeg, zip, tar, gz, 7z, odt, docx, md, rb, mp4, txt' }, status: :bad_request
    end

    @file_content = @file.read

    team = @participant.team
    team.set_student_directory_num

    submit_file_and_create_record

  end

  # POST   /api/v1/submitted_content/folder_action
  # GET   /api/v1/submitted_content/folder_action
  # Perform CRUD operations on the file uploaded.
  def folder_action
    set_participant

    if params[:faction][:delete]
      delete_selected_files
    elsif params[:faction][:rename]
      rename_selected_file
    elsif params[:faction][:move]
      move_selected_file
    elsif params[:faction][:copy]
      copy_selected_file
    elsif params[:faction][:create]
      create_new_folder
    end
  end

  # GET    /api/v1/submitted_content/download
  # Checks for the required file and route and downloads the file.
  def download
    folder_name = params['current_folder']['name']
    file_name = params['download']

    if folder_name.nil?
      render json: { message: 'Folder_name is nil.'}, status: :bad_request
    elsif file_name.nil?
      render json: { message: 'File name is nil.'}, status: :bad_request
    elsif File.directory?("#{folder_name}/#{file_name}")
      render json: { message: 'Cannot send a whole folder.'}, status: :bad_request
    elsif !File.exist?("#{folder_name}/#{file_name}")
      render json: { message: 'File does not exist.'}, status: :not_found
    else
      send_file("#{folder_name}/#{file_name}", disposition: 'inline')
      render json: { message: 'File downloaded.' }, status: :ok
    end
  end

  private

  # Getting all the params from the request.
  def submitted_content_params
    params.require(:submitted_content).permit(:id, :content, :operation, :team_id, :user, :assignment_id)
  end

  # Setting the default instance variable participant.
  def set_participant
    @participant = AssignmentParticipant.find(params[:id])
  end

  # Assigns the directory path for the user
  def set_current_folder
    name = '/'
    if params[:current_folder]
      name = sanitize_folder(params[:current_folder][:name])
    end
    name
  end

  # Delete the selected file.
  def delete_selected_files
    filename = get_filename
    FileUtils.rm_r(filename)
    assignment = @participant.try(:assignment)
    team = @participant.try(:team)
    SubmissionRecord.create(team_id: team.try(:id),
                            content: filename,
                            user: @participant.user.try(:name),
                            assignment_id: assignment.try(:id),
                            operation: 'Remove File')
    render json: { message: 'The selected file has been deleted.' }, status: :ok
  rescue StandardError
    render json: { error: "Failed to delete the file. Reason: #{$ERROR_INFO}" }, status: :unprocessable_entity
  end

  # Saving file to the newly created directory for submission
  def save_file_to_directory(current_directory)
    safe_filename = @file.original_filename.tr('\\', '/')
    safe_filename = sanitize_filename(safe_filename)
    full_filename = current_directory + File.split(safe_filename).last.tr(' ', '_')
    File.open(full_filename, 'wb') { |f| f.write(@file_content) }
    [full_filename, safe_filename]
  end

  # Creating submission record for submit_file function.
  def create_submission_record(full_filename)
    assignment = Assignment.find(@participant.assignment_id)
    team = @participant.team
    SubmissionRecord.create(team_id: team.id,
                            content: full_filename,
                            user: @participant.user.name,
                            assignment_id: assignment.id,
                            operation: 'Submit File')
    render json: { message: 'The file has been submitted.' }, status: :ok
  rescue StandardError
    render json: { message: 'File record failed.' }, status: :unprocessable_entity
  end

  # Create a submission record for hyperlink submission.
  def submit_hyperlink(team)
    begin
      team.submit_hyperlink(params['submission'])
      SubmissionRecord.create(team_id: team.id,
                              content: params['submission'],
                              user: @participant.user.name,
                              assignment_id: @participant.assignment.id,
                              operation: 'Submit Hyperlink')
    rescue StandardError
      return render json: { error: "The URL or URI is invalid. Reason: #{$ERROR_INFO}" }, status: :unprocessable_entity
    end
    render json: { message: 'The link has been successfully submitted.' }, status: :ok
  end

  # Remove hyperlink and create a submission record.
  def remove_hyperlink(hyperlink_to_delete, team)
    begin
      team.remove_hyperlink(hyperlink_to_delete)
      SubmissionRecord.create(team_id: team.id,
                              content: hyperlink_to_delete,
                              user: @participant.user.name,
                              assignment_id: @participant.assignment.id,
                              operation: 'Remove Hyperlink')
    rescue StandardError
      return render json: { error: "There was an error deleting the hyperlink. Reason: #{$ERROR_INFO}" }, status: :unprocessable_entity
    end
    render json: { message: 'The link has been successfully removed.' }, status: :ok
  end

  def submit_file
    current_folder = set_current_folder
    current_directory = @participant.team.path.to_s + current_folder
    FileUtils.mkdir_p(current_directory) unless File.exist? current_directory
    full_filename, safe_filename = save_file_to_directory(current_directory)

    # Unzip if specified in the parameters
    if params['unzip']
      SubmittedContentHelper.unzip_file(full_filename, current_directory, true) if file_type(safe_filename) == 'zip'
    end
    create_submission_record(full_filename)
  end
end
