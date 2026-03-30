module SubmittedContentHelper
  include FileHelper

  # Unzips a file to the specified directory with error handling
  # @param file_name [String] Path to the ZIP file to extract
  # @param unzip_dir [String] Directory where contents will be extracted
  # @param should_delete [Boolean] Whether to delete the ZIP file after extraction
  # @return [Hash] Result hash with :message on success or :error on failure
  def self.unzip_file(file_name, unzip_dir, should_delete)
    # Verify that the ZIP file exists before attempting to unzip
    unless File.exist?(file_name)
      return { error: "Cannot unzip file: '#{file_name}' does not exist. The file may have been moved or deleted." }
    end

    begin
      # Open the ZIP file and extract all entries
      Zip::File.open(file_name) do |zf|
        # Iterate through each entry in the ZIP file
        zf.each do |e|
          # Extract the entry with sanitization
          extract_entry(e, unzip_dir)
        end
      end

      # Delete the original ZIP file if requested
      File.delete(file_name) if should_delete

      # Return success message
      { message: "File unzipped successfully to #{unzip_dir}" }
    rescue Zip::Error => e
      # Handle ZIP-specific errors (corrupted file, invalid format, etc.)
      { error: "Failed to unzip file: #{e.message}. The file may be corrupted or not a valid ZIP archive." }
    rescue StandardError => e
      # Handle any other unexpected errors during unzip
      { error: "Error during unzip operation: #{e.message}. Please try uploading the file again." }
    end
  end

  private

  # Extracts a single ZIP entry to the target directory with path sanitization
  # @param e [Zip::Entry] The ZIP entry to extract
  # @param unzip_dir [String] Target directory for extraction
  def self.extract_entry(e, unzip_dir)
    # Sanitize the entry name to prevent directory traversal attacks (e.g., malicious paths like "../../../etc/passwd")
    # Use only the filename, removing any directory path components
    just_filename = File.basename(e.name)
    safe_name = just_filename.gsub(%r{[^\w\.\_/]}, '_').tr("'", '_')

    # Build the full path where the entry will be extracted
    file_path = File.join(unzip_dir, safe_name)

    # Create parent directories if they don't exist
    FileUtils.mkdir_p(File.dirname(file_path))

    # Extract the entry, overwriting if file already exists (true = overwrite)
    e.extract(file_path) { true }
  end

  # Constructs the full file path from params for file operations
  # @return [String] Full path to the file
  def get_filename
    # Build path from directories and filenames arrays
    # chk_files contains the index of the selected file from the file list
    "#{params[:directories][params[:chk_files]]}/#{params[:filenames][params[:chk_files]]}"
  end

  # Wraps file operations with comprehensive error handling
  # Catches specific errno errors and renders appropriate JSON responses
  # @param operation [String] Description of the operation for error messages
  def handle_file_operation_error(operation)
    # Execute the block containing the file operation
    yield
  rescue Errno::EACCES => e
    # Handle permission denied errors (403 Forbidden)
    render json: { error: "Permission denied while #{operation} the file. You may not have the necessary permissions to perform this action."}, status: :forbidden
  rescue Errno::ENOENT => e
    # Handle file/directory not found errors (404 Not Found)
    render json: { error: "File or directory not found while #{operation}. The file may have been moved or deleted."}, status: :not_found
  rescue Errno::ENOSPC => e
    # Handle insufficient disk space errors (507 Insufficient Storage)
    # Calculate available disk space for more helpful error message
    begin
      stat = File.statvfs(Rails.root)
      available_mb = (stat.bavail * stat.bsize) / 1024 / 1024
      error_msg = "Insufficient disk space while #{operation} the file. Available space: #{available_mb}MB. Please free up disk space or contact your system administrator."
    rescue
      error_msg = "Insufficient disk space while #{operation} the file. Please check available disk space and contact your system administrator if needed."
    end
    render json: { error: error_msg }, status: :insufficient_storage
  rescue StandardError => e
    # Handle all other unexpected errors (422 Unprocessable Entity)
    render json: { error: "Failed while #{operation} the file: #{e.message}. Please verify the file path and try again."}, status: :unprocessable_entity
  end

  # Validates if a file has an allowed extension
  # @param original_filename [String] The filename to check
  # @return [Boolean] true if extension is allowed, false otherwise
  def valid_file_extension?(original_filename)
    # Define list of allowed file extensions
    allowed_extensions = %w[pdf png jpeg jpg zip tar gz 7z odt docx md rb mp4 txt]

    # Extract the file extension (last part after final dot) and convert to lowercase
    file_extension = original_filename&.split('.')&.last&.downcase

    # Check if the extension is in the allowed list
    allowed_extensions.include?(file_extension)
  end

  # Validates if a file size is within the specified limit
  # @param file [File] The file object to check
  # @param size_mb [Integer] Maximum allowed size in megabytes
  # @return [Boolean] true if file size is acceptable, false otherwise
  def check_content_size(file, size_mb)
    # Compare file size (in bytes) against limit (converted from MB to bytes)
    file.size <= size_mb * 1024 * 1024
  end

  # Extracts the file extension without the leading dot
  # @param file_name [String] The filename to extract extension from
  # @return [String] File extension without the dot (e.g., 'txt', 'pdf')
  def file_type(file_name)
    # Get extension with File.extname, then remove the leading dot
    File.extname(file_name).delete('.')
  end

  # Moves a selected file to a new location within the participant's directory
  def move_selected_file
    # Get the source file path from params
    old_filename = get_filename

    # Build the destination path using participant's directory and move location from params
    new_location = File.join(@participant.team.path.to_s, params[:faction][:move])

    # Wrap the move operation with error handling
    handle_file_operation_error('moving') do
      # Create destination directory if it doesn't exist using FileUtils
      FileUtils.mkdir_p(new_location) unless File.exist?(new_location)

      # Move file using FileUtils library
      FileUtils.mv(old_filename, new_location)

      # Render success response
      render json: { message: "The file was successfully moved." }, status: :ok
      return
    end
  end

  # Renames a selected file with validation to prevent conflicts
  def rename_selected_file
    # Get the source file path
    old_filename = get_filename

    # Build new filename with sanitization in the same directory
    new_filename = File.join(params[:directories][params[:chk_files]],
                             clean_filename(params[:faction][:rename]))

    # Wrap the rename operation with error handling
    handle_file_operation_error('renaming') do
      # Check if a file with the new name already exists
      if File.exist?(new_filename)
        render json: { error: "A file named '#{params[:faction][:rename]}' already exists in this directory. Please choose a different name." }, status: :conflict
        return
      end

      # Check if the source file exists
      unless File.exist?(old_filename)
        render json: { error: "Source file not found. It may have been moved or deleted." }, status: :not_found
        return
      end

      # Perform the rename operation
      File.rename(old_filename, new_filename)

      # Render success response
      render json: { message: "File renamed successfully to '#{params[:faction][:rename]}'." }, status: :ok
      return
    end
  end

  # Copies a selected file to a new name in the same directory
  def copy_selected_file
    # Get the source file path
    old_filename = get_filename

    # Build destination filename with sanitization
    new_filename = File.join(params[:directories][params[:chk_files]],
                             clean_filename(params[:faction][:copy]))

    # Wrap the copy operation with error handling
    handle_file_operation_error('copying') do
      # Check if destination file already exists
      if File.exist?(new_filename)
        render json: { error: "A file named '#{params[:faction][:copy]}' already exists in this directory. Please choose a different name or delete the existing file first." }, status: :conflict
        return
      end

      # Check if source file exists
      unless File.exist?(old_filename)
        render json: { error: 'The source file does not exist. It may have been moved or deleted. Please refresh and try again.' }, status: :not_found
        return
      end

      # Copy file recursively (handles both files and directories)
      FileUtils.cp_r(old_filename, new_filename)

      # Render success response
      render json: { message: "File copied successfully to '#{params[:faction][:copy]}'." }, status: :ok
      return
    end
  end

  # Deletes one or more selected files
  def delete_selected_files
    # Wrap the delete operation with error handling
    handle_file_operation_error('deleting') do
      # Track successfully deleted files for response
      deleted_files = []

      # Iterate through each file index in the chk_files param
      Array(params[:chk_files]).each do |idx|
        # Build the full file path for this index
        file_path = File.join(params[:directories][idx], params[:filenames][idx])

        # Check if file exists before attempting deletion
        if File.exist?(file_path)
          # Remove file or directory recursively
          FileUtils.rm_rf(file_path)

          # Add to deleted files list
          deleted_files << file_path
        else
          # File doesn't exist, return error
          render json: { error: "Cannot delete '#{params[:filenames][idx]}': File does not exist. It may have already been deleted." }, status: :not_found
          return
        end
      end

      # Count total deleted files
      file_count = deleted_files.size

      # Render success response with deleted file list
      render json: { message: "Successfully deleted #{file_count} file(s).", files: deleted_files }, status: :no_content
    end
  end

  # Creates a new folder in the participant's directory
  def create_new_folder
    # Build the full path for the new folder
    location = File.join(@participant.team.path.to_s, params[:faction][:create])

    # Wrap the folder creation with error handling
    handle_file_operation_error('creating directory') do
      # Create the directory and any necessary parent directories using FileUtils
      FileUtils.mkdir_p(location)

      # Render success response with folder name
      render json: { message: "Directory '#{params[:faction][:create]}' created successfully." }, status: :created
    end
  end
end
